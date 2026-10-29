use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;

my $pipeline_of = DBIx::Squirrel->can('_pipeline_of_named_stages');

my $f = sub { 'f' };
my $g = sub { 'g' };

# Each case is checked both ways the stages can be passed: as an array
# reference, giving one back, and as a list, giving a list.
my %ways = (
    'array reference' => sub (@stages) { $pipeline_of->([@stages]) },
    'list'            => sub (@stages) { [$pipeline_of->(@stages)] },
);

subtest 'unnamed stages are numbered by position' => sub {
    for my $way (sort keys %ways) {
        my $pipeline = $ways{$way};
        is $pipeline->($f), ['#1' => exact_ref($f)], "$way: one stage";
        is $pipeline->($f, $g),
            ['#1' => exact_ref($f), '#2' => exact_ref($g)],
            "$way: two stages";
    }
};

subtest 'a name before a stage is added to its number' => sub {
    for my $way (sort keys %ways) {
        my $pipeline = $ways{$way};
        is $pipeline->('a', $f), ['#1: a' => exact_ref($f)],
            "$way: named stage";
        is $pipeline->('a', $f, $g),
            ['#1: a' => exact_ref($f), '#2' => exact_ref($g)],
            "$way: named, then unnamed";
        is $pipeline->($f, 'b', $g),
            ['#1' => exact_ref($f), '#2: b' => exact_ref($g)],
            "$way: unnamed, then named: numbers count stages, not arguments";
        is $pipeline->('', $f), ['#1' => exact_ref($f)],
            "$way: an empty name gives the number alone";
        is $pipeline->('0', $f), ['#1: 0' => exact_ref($f)],
            "$way: a false but non-empty name is kept";
    }
};

subtest 'no stages' => sub {
    for my $way (sort keys %ways) {
        is $ways{$way}->(), [], "$way: none";
    }
};

subtest 'the stages passed in are left unchanged' => sub {
    my @stages = ('a', $f, $g);
    $pipeline_of->(\@stages);
    is \@stages, ['a', exact_ref($f), exact_ref($g)], 'array reference';
    $pipeline_of->(@stages);
    is \@stages, ['a', exact_ref($f), exact_ref($g)], 'list';
};

subtest 'invalid stages' => sub {
    my $no_stage = 'Expected a code-reference to follow a non-reference';
    my $bad_ref  = 'Expected a code-reference or non-reference';
    my $here     = 'at ' . __FILE__ . ' line';

    for my $way (sort keys %ways) {
        my $pipeline = $ways{$way};
        like dies { $pipeline->('a') }, qr/^\Q$no_stage\E/x,
            "$way: a name alone";
        like dies { $pipeline->($f, 'x') }, qr/^\Q$no_stage\E/x,
            "$way: a name at the end";
        like dies { $pipeline->('a', 'b', $f) }, qr/^\Q$no_stage\E/x,
            "$way: two names in a row";
        like dies { $pipeline->($f, []) }, qr/^\Q$bad_ref\E/x,
            "$way: an array reference";
        like dies { $pipeline->('a', {}) }, qr/^\Q$no_stage\E/x,
            "$way: a name followed by a hash reference";
    }

    like dies { $pipeline_of->(['a']) }, qr/^\Q$no_stage $here\E/x,
        'reported at the caller';
    like dies { $pipeline_of->([[]]) }, qr/^\Q$bad_ref $here\E/x,
        'an array reference alone, in an array reference';
};

done_testing;
