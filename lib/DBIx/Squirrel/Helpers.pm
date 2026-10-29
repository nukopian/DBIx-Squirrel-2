use v5.36;

package DBIx::Squirrel::Helpers;

use Carp      qw(croak);
use Exporter  qw(import);
use Ref::Util qw(is_arrayref is_coderef);

our @CARP_NOT  = qw(DBIx::Squirrel);
our @EXPORT_OK = qw(pipeline_ordered_stages);

# Return a list of closures as a list of pairs of named closures.
sub pipeline_ordered_stages (@stages) {
    my @pipeline;
    for (my $n = 1; @stages; $n += 1) {
        my $s = shift @stages;
        if (is_coderef($s)) {
            push @pipeline, ("#$n" => $s);
            next;
        }
        croak "Expected a code-reference or non-reference" if ref $s;
        croak "Expected a code-reference to follow a non-reference"
            unless @stages && is_coderef($stages[0]);
        push @pipeline, ((length($s) ? "#$n: $s" : "#$n") => shift @stages);
    }
    return @pipeline;
}

1;
