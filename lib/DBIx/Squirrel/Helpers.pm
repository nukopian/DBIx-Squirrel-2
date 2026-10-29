use v5.36;

package DBIx::Squirrel::Helpers;

use experimental qw(try);

use Carp      qw(croak);
use Exporter  qw(import);
use Ref::Util qw(is_arrayref is_coderef);

our @CARP_NOT  = qw(DBIx::Squirrel);
our @EXPORT_OK = qw(order_stages);


# Return a list of closures as a list of pairs of named closures.
sub pipeline (@stages) {
    my @p;
    for (my $n = 1; @stages; $n += 1) {
        my $s = shift @stages;
        croak "Expected a code-reference" unless is_coderef($s);
        push @p, ("#$n" => $s);
    }
    return sub (@xs) {
        my @pipeline = @p;
        while (@pipeline) {
            my($id, $stage) = splice @pipeline, 0, 2;
            try {
                @xs = $stage->(@xs);
                last unless @xs;
            }
            catch ($e) {
                last if $e isa 'DBIx::Squirrel::Stop';
                croak "Pipeline stage $id failed: $e";
            }
        }
    };
}

1;
