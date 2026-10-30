use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;
use DBIx::Squirrel::Stop;

package My::Squirrel {
    our @ISA = 'DBIx::Squirrel';
}

subtest 'the first stage is called with the invocant' => sub {
    my $arg = sub ($x) { $x };
    is [DBIx::Squirrel->pipe($arg)],     ['DBIx::Squirrel'], 'as its argument';
    is [My::Squirrel->pipe(sub { $_ })], ['My::Squirrel'],   'and in $_';
};

subtest 'with no stages, pipe returns the invocant' => sub {
    is [DBIx::Squirrel->pipe], ['DBIx::Squirrel'];
};

subtest 'each value goes through the rest of the stages on its own' => sub {
    my @results = DBIx::Squirrel->pipe(
        sub { (3, 4, 5) },
        sub { $_ % 2 ? $_ : () },
        sub { $_ * 2 },
    );
    is \@results, [6, 10];
};

subtest 'in scalar context, pipe returns the first value' => sub {
    my $first = DBIx::Squirrel->pipe(sub { (3, 4, 5) });
    is $first, 3, 'of several';

    my $none = DBIx::Squirrel->pipe(sub { () });
    is $none, undef, 'or undef, if there are none';
};

subtest 'Stop ends the pipeline' => sub {
    my @results = DBIx::Squirrel->pipe(
        sub { (1, 2, 3) },
        sub { $_ == 2 ? Stop('two') : $_ },
    );
    is \@results, [1, 'two'];
};

subtest 'a stage that dies is reported where pipe was called' => sub {
    my @stages = (sub { $_ }, sub { die "boom\n" });       ## no critic (ErrorHandling::RequireCarping)
    my $line   = __LINE__ + 1;
    my $err    = dies { DBIx::Squirrel->pipe(@stages) };
    is $err,
        "Pipeline stage #2 failed at ${\ __FILE__ } line $line:\n    boom\n";
};

subtest 'a stage that is not a code reference' => sub {
    my @stages = (sub { $_ }, 'x');
    my $line   = __LINE__ + 1;
    my $err    = dies { DBIx::Squirrel->pipe(@stages) };
    is $err, "Stage #2 is not a code-reference at ${\ __FILE__ } line $line.\n";
};

done_testing;
