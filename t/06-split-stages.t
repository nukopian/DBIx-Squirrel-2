use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel::Helpers qw(split_stages);

my $s1 = sub { 1 };
my $s2 = sub { 2 };

subtest 'split_stages splits the trailing code references off' => sub {
    my($stages, @rest) = split_stages(1, undef, $s1, $s2);
    ref_is $stages->[0], $s1, 'the first stage';
    ref_is $stages->[1], $s2, 'the second stage';
    is scalar(@$stages), 2,          'no others';
    is \@rest,           [1, undef], 'the rest, in order';
};

subtest 'only the trailing ones' => sub {
    my($stages, @rest) = split_stages($s1, 1, $s2);
    ref_is $stages->[0], $s2, 'the stage';
    is scalar(@$stages), 1, 'only that one';
    is scalar(@rest),    2, 'the rest';
    ref_is $rest[0], $s1, 'a code reference before them stays in the rest';
};

subtest 'all stages, or none' => sub {
    my($stages, @rest) = split_stages($s1, $s2);
    is scalar(@$stages), 2,  'all stages';
    is \@rest,           [], 'no rest';

    ($stages, @rest) = split_stages(1, 2);
    is $stages, [],     'no stages';
    is \@rest,  [1, 2], 'all rest';

    ($stages, @rest) = split_stages();
    is $stages, [], 'nothing at all';
    is \@rest, [];
};

done_testing;
