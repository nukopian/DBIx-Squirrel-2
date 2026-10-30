use v5.36;

package DBIx::Squirrel::st;

use DBI                   qw();
use DBIx::Squirrel::Pipes qw();

our @ISA = ('DBI::st', 'DBIx::Squirrel::Pipes');

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::st - DBIx::Squirrel's statement handle class

=head1 DESCRIPTION

A statement handle prepared on a DBIx::Squirrel database handle is
blessed into this class, a subclass of the DBI's C<DBI::st>, so it does
everything a DBI statement handle does. It also inherits
L<DBIx::Squirrel/pipe> and L<DBIx::Squirrel/tap> from
L<DBIx::Squirrel::Pipes>.

=head1 SEE ALSO

L<DBIx::Squirrel>, L<DBI>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
