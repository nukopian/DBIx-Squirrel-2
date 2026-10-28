use v5.36;

package    # hide from PAUSE
    DBIx::Squirrel::Stop;

use overload '""' => sub { "Stop used outside a pipeline\n" }, fallback => 1;

use Carp qw(croak);

my $STOP = bless \(my $x), __PACKAGE__;

sub throw ($class) { croak $STOP }

1;
