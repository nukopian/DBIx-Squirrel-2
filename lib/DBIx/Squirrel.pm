use v5.36;

package DBIx::Squirrel;

use experimental qw(try);

use Carp      qw(croak);
use DBI       qw();
use Ref::Util qw(is_hashref);

use DBIx::Squirrel::Helpers qw(order_stages);
use DBIx::Squirrel::Stop    qw();

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
sub pipe ($self, @stages) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my @res      = $self;
    my @pipeline = order_stages(@stages);
    while (@pipeline) {
        my($id, $stage) = splice @pipeline, 0, 2;
        try {
            @res = $stage->(@res);
            last unless @res;
        }
        catch ($e) {
            last if $e isa 'DBIx::Squirrel::Stop';
            croak "pipe ($id) failed: $e";
        }
    }
    return wantarray ? @res : $res[0];
}

# Run a queue of closures against the database-handle for their
# side-effects.
sub tap ($self, @stages) {
    my @res      = $self;
    my @pipeline = order_stages(@stages);
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

1;

__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel - DBI, minus the boilerplate, plus a pipeline

=head1 SYNOPSIS

    use DBIx::Squirrel;

    my $dbh = DBIx::Squirrel->connect($data_source, $username, $password, \%attr);

    # A new connection with the same parameters as an existing one
    my $other = DBIx::Squirrel->connect($dbh, \%attr);

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

=head2 Stop

    use DBIx::Squirrel::Stop;
    Stop();

    DBIx::Squirrel::Stop->throw;

Called from a stage of a pipeline, ends the pipeline quietly: the rest
of that stage, and the stages after it, don't run. C<Stop> is exported automatically by
L<DBIx::Squirrel::Stop>; C<< DBIx::Squirrel::Stop->throw >> does the same
without importing it.

Stop works by throwing an exception, which the pipeline catches. So a stage that catches errors itself, with C<eval> or C<try>,
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

=item Stop used outside a pipeline

L</Stop> was called where no pipeline was running to catch it.

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
