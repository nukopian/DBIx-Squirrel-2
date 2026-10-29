use v5.36;

package DBIx::Squirrel::Helpers;

use Carp      qw(croak);
use Exporter  qw(import);
use Ref::Util qw(is_arrayref is_coderef);

our @CARP_NOT  = qw(DBIx::Squirrel);
our @EXPORT_OK = qw(pipeline_ordered_stages);

# Return a list of closures as a list of pairs of named closures.
sub pipeline_ordered_stages (@args) {
    my @pipeline;
    my $wantarrayref = @args == 1 && is_arrayref($args[0]);
    my @stages       = $wantarrayref ? $args[0]->@* : @args;
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
