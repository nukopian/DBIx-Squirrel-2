use v5.36;

package DBIx::Squirrel;

use experimental qw(try);

use Carp      qw(croak);
use DBI       qw();
use Ref::Util qw(is_arrayref is_coderef is_hashref);

use DBIx::Squirrel::Stop qw();

our @ISA     = 'DBI';
our $VERSION = 'v2.0.0';

# Return the handle of the connection to the requested data source.
sub connect ($class, $source, @args) {
    return _connect_dbh($class, $source, @args)
        if $source isa 'DBI::db';

    my($username, $password);
    $username = shift @args unless is_hashref($args[0]);
    $password = shift @args unless is_hashref($args[0]);

    my $attrs = @args && is_hashref($args[0]) ? shift @args : {};

    my $dbh = $class->SUPER::connect(
        $source,
        $username,
        $password, {
            %$attrs,
            RootClass => ref($class) || $class,
        },
    );

    croak $DBI::errstr unless $dbh;

    return $dbh;
}

# Return the handle of a new connection using the same parameters as
# another connection.
sub _connect_dbh ($class, $dbh, @args) {
    my $attrs = @args && is_hashref($args[0]) ? shift @args : {};

    $dbh = $dbh->clone({
        %$attrs,
        RootClass => ref($class) || $class,
    });

    croak $DBI::errstr unless $dbh;

    return $dbh;
}

# Run a queue of closures against the database-handle.
sub and_then ($self, @stages) {
    my @res      = $self;
    my @pipeline = _pipeline_of_named_stages(\@stages)->@*;
    while (@pipeline) {
        my($id, $stage) = splice @pipeline, 0, 2;
        try {
            @res = $stage->(@res);
            last unless @res;
        }
        catch ($e) {
            last if $e isa 'DBIx::Squirrel::Stop';
            croak "and_then ($id) failed: $e";
        }
    }
    return wantarray ? @res : $res[0];
}

# Run a queue of closures against the database-handle for their
# side-effects.
sub tap ($self, @stages) {
    my @res      = $self;
    my @pipeline = _pipeline_of_named_stages(\@stages)->@*;
    while (@pipeline) {
        my($id, $stage) = splice @pipeline, 0, 2;
        try {
            @res = $stage->(@res);
            last unless @res;
        }
        catch ($e) {
            last if $e isa 'DBIx::Squirrel::Stop';
            croak "tap ($id) failed: $e";
        }
    }
    return $self;
}

# Return a list of closures as a list of pairs of named closures.
sub _pipeline_of_named_stages (@args) {
    my @pipeline;
    my $wantarrayref = @args == 1 && is_arrayref($args[0]);
    my @stages       = $wantarrayref ? @{ $args[0] } : @args;
    my $p            = 0;
    while (@stages) {
        my $s = shift @stages;
        $p += 1;
        if (is_coderef($s)) {
            push @pipeline, ("#$p" => $s);
            next;
        }
        croak "Expected a code-reference or non-reference" if ref $s;
        croak "Expected a code-reference to follow a non-reference"
            unless @stages && is_coderef($stages[0]);
        push @pipeline, ((length($s) ? "#$p: $s" : "#$p") => shift @stages);
    }
    return $wantarrayref ? \@pipeline : @pipeline;
}

1;

__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel - DBI, minus the boilerplate, plus a pipeline

=head1 SYNOPSIS

    use DBIx::Squirrel;
    use DBIx::Squirrel::Stop;

    my $dbh = DBIx::Squirrel->connect($data_source, $username, $password, \%attr);

    # A new connection with the same parameters as an existing one
    my $other = DBIx::Squirrel->connect($dbh, \%attr);

    # Pass values from stage to stage, and get the last stage's results
    my @results = DBIx::Squirrel->and_then(
        sub ($invocant) { ... },
        'a named stage' => sub (@values) { ... },
        sub (@values) { Stop() if $done; ... },
    );

    # The same, as a branch off to the side: get the invocant back
    my $invocant = DBIx::Squirrel->tap(
        sub ($invocant) { ... },
        sub (@values)   { ... },
    );

=head1 DESCRIPTION

DBIx::Squirrel keeps you writing SQL, as the L<DBI> does, and takes away
the friction around it: placeholders in whatever style you like,
iterators over results, and a pipeline of transformations declared
beside the query.

It subclasses the DBI, so everything the DBI does still works, and
where the two do the same thing they give the same result. This page
notes where they differ.

B<In development.> This is the successor to DBIx-Squirrel 1.x, being
rewritten for Perl 5.36 or later, and much of it is still to come. In
particular, DBIx::Squirrel's own database and statement handle classes
don't exist yet, so L</connect> returns the DBI's own handles for now,
and the DBI warns that it can't use DBIx::Squirrel's.

=head1 METHODS

=head2 connect

    $dbh = DBIx::Squirrel->connect($data_source, $username, $password);
    $dbh = DBIx::Squirrel->connect($data_source, $username, $password, \%attr);
    $dbh = DBIx::Squirrel->connect($dbh, \%attr);

Connects to a data source, as the DBI's C<connect> does, and returns a
database handle.

Unlike the DBI's C<connect>, it B<always croaks> if the connection
fails, whatever C<RaiseError> is set to, with the DBI's error message,
reported at the line that called C<connect>. The DBI returns C<undef>
unless C<RaiseError> is set.

Called on a subclass of DBIx::Squirrel, it uses that subclass's database
and statement handle classes in place of DBIx::Squirrel's.

=head3 Connecting with an existing handle

Given a database handle in place of a data source, C<connect> makes a
new connection with the same parameters, using the DBI's C<clone>. Any
attributes passed are applied to the new connection. The handle can
come from the DBI itself, or from code that made its own connection.

The new handle is a separate connection, not a second name for the
first: it doesn't share the first one's transaction, temporary tables
or session settings. An in-memory SQLite database, for example, gives
a new, empty database.

=head3 connect_cached

C<connect_cached> is the DBI's own, unchanged. The DBI's C<connect_cached>
calls C<connect> when it needs a new connection, so it croaks on failure
too.

=head2 and_then

    @results = $invocant->and_then(@stages);
    $result  = $invocant->and_then(@stages);

Runs a list of stages as a pipeline, and returns what the last one
returned.

Each stage is a code reference. The first is called with the invocant,
and each one after it with whatever the stage before returned, so a
stage can pass on one value, several, or none:

    use List::Util qw(sum);

    my $total = DBIx::Squirrel->and_then(
        sub ($invocant) { (3, 4, 5) },
        sub (@numbers)  { sum(@numbers) },
        'double it' => sub ($sum) { $sum * 2 },
    );    # 24

A string before a stage names it, for error messages, as with
C<'double it'> above. Stages are numbered by position, from C<#1>,
whether they're named or not.

A stage that returns an empty list ends the pipeline: the stages after
it don't run, and C<and_then> returns an empty list. Any other return
carries on, including C<undef> and other false values, which are
passed on like any other. To end the pipeline early and keep the
values reached so far, call L</Stop>: C<and_then> then returns what the
stage before the stopping one returned.

Called in list context, C<and_then> returns all the values. In scalar
context, it returns the first, or C<undef> if there are none.

A stage is called with as many arguments as the stage before returned,
so a stage after one that returns a list should accept a list, as
C<sub (@numbers)> does above. A signature for fewer arguments dies,
which C<and_then> reports as the stage failing.

If a stage dies, C<and_then> croaks at the line that called it, naming
the stage, and the stages after it don't run:

    and_then (#3: double it) failed: ...

=head2 tap

    $invocant = $invocant->tap(@stages);

Runs a list of stages as a branch off to the side, for their side
effects, and returns the invocant, so that a chain of method calls can
carry on after it.

The stages work as they do in L</and_then>: the first is called with
the invocant, each one after it with what the stage before returned,
and an empty list or L</Stop> ends the branch early. The difference is
that the branch's results are dropped, and C<tap> returns the invocant
however the branch ended.

    $invocant ───┬───▶ $invocant
                 │
                 └───▶ stage #1 ───▶ stage #2 ───▶ ...

For example, to log a report on the invocant, then carry on with it:

    $invocant->tap(
        sub ($invocant) { $invocant->report },
        sub ($report)   { log_report($report) },
    )->carry_on;

A stage passes on whatever its last statement gives, even one run for
its side effects. So each stage except the last should return what the
next one needs; the last can return anything.

If a stage dies, C<tap> croaks at the line that called it, naming the
stage, and the stages after it don't run:

    tap (#2) failed: ...

=head2 Stop

    use DBIx::Squirrel::Stop;
    Stop();

    DBIx::Squirrel::Stop->throw;

Called from a stage of L</and_then> or L</tap>, ends the stages quietly:
the rest of that stage, and the stages after it, don't run, and the
method returns as usual. C<Stop> is exported automatically by
L<DBIx::Squirrel::Stop>; C<< DBIx::Squirrel::Stop->throw >> does the same
without importing it.

Stop works by throwing an exception, which C<and_then> and C<tap>
catch. So a stage that catches errors itself, with C<eval> or C<try>,
should throw a stop on again:

    sub ($invocant) {
        try { ... }
        catch ($e) {
            die $e if $e isa 'DBIx::Squirrel::Stop';
            ...
        }
    }

Called outside a stage, it dies with "Stop used outside a pipeline".
L<DBIx::Squirrel::Stop> says more, including what a stop carries.

=head1 DIAGNOSTICS

=over

=item and_then (%s) failed: %s

=item tap (%s) failed: %s

A stage passed to L</and_then> or L</tap> died. The part in brackets
names the stage, by its position and any name given to it; the rest is
the stage's error.

=item Expected a code-reference to follow a non-reference

A name was passed to L</and_then> or L</tap> with no stage after it.
No stage runs.

=item Expected a code-reference or non-reference

Something passed to L</and_then> or L</tap> was neither a stage nor a
name, such as an array or hash reference. No stage runs.

=item Stop used outside a pipeline

L</Stop> was called where no C<and_then> or C<tap> was running to catch
it.

=back

=head1 SEE ALSO

L<DBI>, L<DBIx::Squirrel::Stop>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
