use v5.36;

package DBIx::Squirrel::Stop;

use overload '""' => sub { "Stop used outside a pipeline\n" }, fallback => 1;

use Carp     qw(croak);
use Exporter qw(import);

our @EXPORT = qw(Stop);    ## no critic (Modules::ProhibitAutomaticExportation)

# Syntactic sugar throwing the exception that stops a pipeline early.
sub Stop (@data) {
    return __PACKAGE__->throw(@data);
}

# Throws an exception that stops a pipeline early.
sub throw ($class, @data) {
    $class = __PACKAGE__
        unless $class->isa(__PACKAGE__);
    croak bless([$class, @data], $class);
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Stop - end a DBIx::Squirrel pipeline early

=head1 SYNOPSIS

    use DBIx::Squirrel;
    use DBIx::Squirrel::Stop;

    my @results = DBIx::Squirrel->pipe(
        sub ($invocant) { ... },
        sub (@values)   { Stop() if $done; ... },
        sub (@values)   { ... },
    );

    # The same, without importing Stop
    sub (@values) { DBIx::Squirrel::Stop->throw if $done; ... }

=head1 DESCRIPTION

A stop is the exception that ends the stages of
L<DBIx::Squirrel/pipe> or L<DBIx::Squirrel/tap> early and quietly:
the rest of the stage that throws it, and the stages after it, don't
run, and the method returns as usual. C<pipe> returns what the
stage before the stopping one returned; C<tap> returns its invocant.

=head1 FUNCTIONS

=head2 Stop

    Stop();
    Stop(@data);

Throws a stop carrying C<@data>. It's the same as
C<< DBIx::Squirrel::Stop->throw(@data) >>, and is exported by
default.

To keep it out of your namespace:

    use DBIx::Squirrel::Stop ();

=head1 METHODS

=head2 throw

    DBIx::Squirrel::Stop->throw;
    DBIx::Squirrel::Stop->throw(@data);
    My::Stop->throw(@data);

Throws a stop carrying C<@data>, blessed into the class it was called
on, so a subclass of DBIx::Squirrel::Stop throws one of its own. Called
on a class that isn't a stop, it throws a plain DBIx::Squirrel::Stop.

=head1 THE STOP

A stop is an array reference, blessed into its class. Its first element
is that class, and the rest are the data it was thrown with:

    eval { DBIx::Squirrel::Stop->throw(1, 2) };
    my $stop = $@;    # bless ['DBIx::Squirrel::Stop', 1, 2], 'DBIx::Squirrel::Stop'

C<pipe> and C<tap> don't use the data. It's there for code that
catches a stop itself.

As a string, a stop is "Stop used outside a pipeline", with a newline,
which is what a user sees if one is thrown with nothing to catch it.

=head2 Catching errors in a stage

C<pipe> and C<tap> recognise a stop with C<isa>, so a subclass of
DBIx::Squirrel::Stop stops them too. A stage that catches errors
itself, with C<eval> or C<try>, should throw a stop on again:

    sub ($invocant) {
        try { ... }
        catch ($e) {
            die $e if $e isa 'DBIx::Squirrel::Stop';
            ...
        }
    }

=head1 DIAGNOSTICS

=over

=item Stop used outside a pipeline

A stop was thrown where no C<pipe> or C<tap> was running to catch
it.

=back

=head1 SEE ALSO

L<DBIx::Squirrel>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
