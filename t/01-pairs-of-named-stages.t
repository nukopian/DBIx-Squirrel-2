use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;

my $pairs_of = DBIx::Squirrel->can('_pairs_of_named_stages');

my $f = sub { 'f' };
my $g = sub { 'g' };

subtest 'unnamed stages are numbered by position' => sub {
    is $pairs_of->([$f]), ['#1' => exact_ref($f)], 'one stage';
    is $pairs_of->([$f, $g]),
        ['#1' => exact_ref($f), '#2' => exact_ref($g)],
        'two stages';
};

subtest 'a name before a stage is added to its number' => sub {
    is $pairs_of->(['a', $f]), ['#1: a' => exact_ref($f)], 'named stage';
    is $pairs_of->(['a', $f, $g]),
        ['#1: a' => exact_ref($f), '#2' => exact_ref($g)],
        'named, then unnamed';
    is $pairs_of->([$f, 'b', $g]),
        ['#1' => exact_ref($f), '#2: b' => exact_ref($g)],
        'unnamed, then named: numbers count stages, not arguments';
    is $pairs_of->(['', $f]), ['#1' => exact_ref($f)],
        'an empty name gives the number alone';
    is $pairs_of->(['0', $f]), ['#1: 0' => exact_ref($f)],
        'a false but non-empty name is kept';
};

subtest 'no stages' => sub {
    is $pairs_of->([]), [], 'an empty list';
    is $pairs_of->(),   [], 'no argument';
};

subtest 'the stages passed in are left unchanged' => sub {
    my @stages = ('a', $f, $g);
    $pairs_of->(\@stages);
    is \@stages, ['a', exact_ref($f), exact_ref($g)];
};

subtest 'invalid stages' => sub {
    my $no_stage = 'Expected a code-reference to follow a non-reference';
    my $bad_ref  = 'Expected a code-reference or non-reference';
    my $here     = 'at ' . __FILE__ . ' line';

    like dies { $pairs_of->(['a']) }, qr/^\Q$no_stage $here\E/x,
        'a name alone, reported at the caller';
    like dies { $pairs_of->([$f, 'x']) }, qr/^\Q$no_stage\E/x,
        'a name at the end';
    like dies { $pairs_of->(['a', 'b', $f]) }, qr/^\Q$no_stage\E/x,
        'two names in a row';
    like dies { $pairs_of->([[]]) }, qr/^\Q$bad_ref $here\E/x,
        'an array reference, reported at the caller';
    like dies { $pairs_of->(['a', {}]) }, qr/^\Q$no_stage\E/x,
        'a name followed by a hash reference';
};

done_testing;
