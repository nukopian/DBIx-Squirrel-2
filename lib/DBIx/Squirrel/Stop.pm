use v5.36;

package DBIx::Squirrel::Stop;

use overload '""' => sub { "Stop used outside a pipeline\n" }, fallback => 1;

use Carp     qw(croak);
use Exporter qw(import);

our @EXPORT_OK = qw(Stop);

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
