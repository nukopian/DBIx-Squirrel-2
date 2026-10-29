use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;
use DBIx::Squirrel::Stop qw(Stop);

package My::Squirrel {
    our @ISA = 'DBIx::Squirrel';
}

package My::Stop {
    our @ISA = 'DBIx::Squirrel::Stop';
}

my $here = 'at ' . __FILE__ . ' line';

subtest 'values flow from stage to stage' => sub {
    my $self = bless {}, 'My::Squirrel';
    my @seen;
    my @results = $self->and_then(
        sub ($s) { push @seen, ['a', $s]; (3, 4, 5) },
        b => sub (@v) { push @seen, ['b', @v]; $v[0] + $v[1] + $v[2] },
        sub ($sum) { push @seen, ['c', $sum]; $sum * 2 },
    );
    is \@seen, [['a', exact_ref($self)], ['b', 3, 4, 5], ['c', 12]],
        'the first stage gets the invocant, the rest what came before';
    is \@results, [24], "returns the last stage's results";
};

subtest 'list and scalar context' => sub {
    my @stages = (sub { (5, 6, 7) });
    is [DBIx::Squirrel->and_then(@stages)],       [5, 6, 7], 'list: every value';
    is scalar(DBIx::Squirrel->and_then(@stages)), 5, 'scalar: the first value';
    is scalar(DBIx::Squirrel->and_then(sub { 42 })), 42,
        'scalar: a single value';
};

subtest 'no stages' => sub {
    is scalar(DBIx::Squirrel->and_then), 'DBIx::Squirrel',
        'returns the invocant';
};

subtest 'an empty return ends the pipeline' => sub {
    my @ran;
    my @stages = (
        sub { push @ran, 'a'; return },
        sub { push @ran, 'b'; 'never' },
    );
    is [DBIx::Squirrel->and_then(@stages)],       [],    'list: an empty list';
    is \@ran,                                     ['a'], "later stages don't run";
    is scalar(DBIx::Squirrel->and_then(@stages)), undef, 'scalar: undef';
};

subtest 'undef and other false values are passed on' => sub {
    my @seen;
    my @results = DBIx::Squirrel->and_then(
        sub { undef },
        sub (@v) { push @seen, [@v]; 0 },
        sub (@v) { push @seen, [@v]; '' },
        sub (@v) { push @seen, [@v]; 'end' },
    );
    is \@seen,    [[undef], [0], ['']];
    is \@results, ['end'];
};

subtest 'Stop ends the pipeline, keeping the values reached' => sub {
    my %ways = (
        'exported' => sub { Stop() },
        'thrown'   => sub { DBIx::Squirrel::Stop->throw },
        'subclass' => sub { My::Stop->throw },
    );
    for my $way (sort keys %ways) {
        my @ran;
        my @results;
        ok lives {
            @results = DBIx::Squirrel->and_then(
                sub { push @ran, 'a'; ('kept', 'too') },
                sub { push @ran, 'b'; $ways{$way}->(); push @ran, 'b-after' },
                sub { push @ran, 'c' },
            );
        }, "$way: doesn't die";
        is \@ran,     [qw(a b)],       "$way: later stages don't run";
        is \@results, ['kept', 'too'], "$way: returns the values before Stop";
    }
};

subtest 'a stage given more arguments than it takes fails' => sub {
    my $too_many = 'and_then (#2) failed: Too many arguments';
    like dies {
        DBIx::Squirrel->and_then(sub { (1, 2, 3) }, sub ($one) { $one });
    }, qr/^\Q$too_many\E/x;
};

subtest 'a failing stage is named in the error' => sub {
    my $named   = "and_then (#2: b) failed: boom\n";
    my $unnamed = "and_then (#1) failed: boom\n";
    my @ran;
    like dies {
        DBIx::Squirrel->and_then(
            sub { push @ran, 'a'; 1 },
            b => sub { die "boom\n" },
            sub { push @ran, 'c' },
        );
    }, qr/^\Q$named\E\s*\Q$here\E/x, 'named stage, reported at the caller';
    is \@ran, ['a'], "later stages don't run";

    like dies {
        DBIx::Squirrel->and_then(sub { die "boom\n" });
    }, qr/^\Q$unnamed\E/x, 'unnamed stage';
};

subtest 'invalid stages fail before any stage runs' => sub {
    my @ran;
    like dies {
        DBIx::Squirrel->and_then(sub { push @ran, 'a' }, 'b');
    }, qr/^\QExpected a code-reference to follow a non-reference $here\E/x;
    is \@ran, [], 'no stage ran';
};

done_testing;
