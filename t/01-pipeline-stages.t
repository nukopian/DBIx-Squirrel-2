use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel::Helpers qw(pipeline_stages);

my $f = sub { 'f' };
my $g = sub { 'g' };

sub pipeline (@stages) { [pipeline_stages(@stages)] }

subtest 'unnamed stages are numbered by position' => sub {
    is pipeline($f), ['#1' => exact_ref($f)], 'one stage';
    is pipeline($f, $g),
        ['#1' => exact_ref($f), '#2' => exact_ref($g)],
        'two stages';
};

subtest 'a name before a stage is added to its number' => sub {
    is pipeline('a', $f), ['#1: a' => exact_ref($f)], 'named stage';
    is pipeline('a', $f, $g),
        ['#1: a' => exact_ref($f), '#2' => exact_ref($g)],
        'named, then unnamed';
    is pipeline($f, 'b', $g),
        ['#1' => exact_ref($f), '#2: b' => exact_ref($g)],
        'unnamed, then named: numbers count stages, not arguments';
    is pipeline('', $f), ['#1' => exact_ref($f)],
        'an empty name gives the number alone';
    is pipeline('0', $f), ['#1: 0' => exact_ref($f)],
        'a false but non-empty name is kept';
};

subtest 'no stages' => sub {
    is pipeline(), [], 'none';
};

subtest 'the stages passed in are left unchanged' => sub {
    my @stages = ('a', $f, $g);
    pipeline_stages(@stages);
    is \@stages, ['a', exact_ref($f), exact_ref($g)], 'list';
};

subtest 'invalid stages' => sub {
    my $no_stage = 'Expected a code-reference to follow a non-reference';
    my $bad_ref  = 'Expected a code-reference or non-reference';
    my $here     = 'at ' . __FILE__ . ' line';

    like dies { pipeline('a') }, qr/^\Q$no_stage\E/x, 'a name alone';
    like dies { pipeline($f, 'x') }, qr/^\Q$no_stage\E/x,
        'a name at the end';
    like dies { pipeline('a', 'b', $f) }, qr/^\Q$no_stage\E/x,
        'two names in a row';
    like dies { pipeline($f, []) }, qr/^\Q$bad_ref\E/x, 'an array reference';
    like dies { pipeline('a', {}) }, qr/^\Q$no_stage\E/x,
        'a name followed by a hash reference';
    like dies { pipeline([$f]) }, qr/^\Q$bad_ref\E/x,
        'an array reference of stages is not unpacked';

    like dies { pipeline_stages('a') }, qr/^\Q$no_stage $here\E/x,
        'reported at the caller';
};

done_testing;
