use v5.36;

package DBIx::Squirrel::Helpers;

use Exporter  qw(import);
use Ref::Util qw(is_coderef);

use namespace::clean -except => 'import';

our @EXPORT_OK = qw(split_stages);

# Split the trailing code-references off a list; return them in an array
# reference, and the rest.
sub split_stages (@args) {
    my $n = @args;
    while ($n && is_coderef($args[$n - 1])) { $n -= 1 }
    my @stages = splice @args, $n;
    return \@stages, @args;
}

1;
