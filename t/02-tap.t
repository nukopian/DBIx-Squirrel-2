use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;
use DBIx::Squirrel::Stop;

package My::Squirrel {
    our @ISA = 'DBIx::Squirrel';
}

subtest 'tap returns the invocant' => sub {
    is DBIx::Squirrel->tap(sub { 'something else' }), 'DBIx::Squirrel',
        'the class';
    is My::Squirrel->tap(sub { () }), 'My::Squirrel',   'a subclass';
    is DBIx::Squirrel->tap,           'DBIx::Squirrel', 'with no stages';

    my @all = DBIx::Squirrel->tap(sub { (1, 2, 3) });
    is \@all, ['DBIx::Squirrel'], 'and only the invocant, in list context';
};

subtest 'the stages run for their side effects' => sub {
    my @seen;
    my $arg = sub ($x) { push @seen, "first($x)"; (1, 2, 3) };
    DBIx::Squirrel->tap(
        $arg,
        sub { $_ % 2 ? $_ : () },
        sub { push @seen, "last($_)"; $_ },
    );
    is \@seen, ['first(DBIx::Squirrel)', 'last(1)', 'last(3)'];
};

subtest 'Stop ends the stages, and tap still returns the invocant' => sub {
    my @seen;
    my $invocant = DBIx::Squirrel->tap(
        sub { (1, 2, 3) },
        sub { $_ == 2 ? Stop('two') : $_ },
        sub { push @seen, $_ },
    );
    is $invocant, 'DBIx::Squirrel', 'the invocant';
    is \@seen,    [1, 'two'],       'the stages ran until the Stop';
};

subtest 'a stage that dies is reported where tap was called' => sub {
    my @stages = (sub { $_ }, sub { die "boom\n" });      ## no critic (ErrorHandling::RequireCarping)
    my $line   = __LINE__ + 1;
    my $err    = dies { DBIx::Squirrel->tap(@stages) };
    is $err,
        "Pipeline stage #2 failed at ${\ __FILE__ } line $line:\n    boom\n";
};

subtest 'a stage that is not a code reference' => sub {
    my @stages = (sub { $_ }, 'x');
    my $line   = __LINE__ + 1;
    my $err    = dies { DBIx::Squirrel->tap(@stages) };
    is $err, "Stage #2 is not a code-reference at ${\ __FILE__ } line $line.\n";
};

done_testing;
