use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;

package My::Squirrel {
    our @ISA = 'DBIx::Squirrel';
}

my $here = 'at ' . __FILE__ . ' line';

subtest 'values flow along the branch, and the invocant comes back' => sub {
    my $self = bless {}, 'My::Squirrel';
    my @seen;
    my $result = $self->tap(
        sub ($s) { push @seen, ['a', $s]; (1, 2) },
        b => sub (@v) { push @seen, ['b', @v]; 3 },
        sub (@v) { push @seen, ['c', @v]; 'dropped' },
    );
    is \@seen, [['a', exact_ref($self)], ['b', 1, 2], ['c', 3]],
        'the first stage gets the invocant, the rest what came before';
    ref_is $result, $self, 'returns the invocant, not the results';
};

subtest 'as a class method' => sub {
    my @seen;
    my $result = DBIx::Squirrel->tap(sub ($s) {
        push @seen, $s;
    });
    is $result, 'DBIx::Squirrel',   'returns the class';
    is \@seen,  ['DBIx::Squirrel'], 'the first stage gets the class';
};

subtest 'no stages' => sub {
    is DBIx::Squirrel->tap, 'DBIx::Squirrel', 'returns the invocant';
};

subtest 'an empty return ends the branch' => sub {
    my @ran;
    my $result = DBIx::Squirrel->tap(
        sub { push @ran, 'a'; return },
        sub { push @ran, 'b' },
    );
    is \@ran,   ['a'],            "later stages don't run";
    is $result, 'DBIx::Squirrel', 'returns the invocant';
};

subtest 'undef and other false values are passed on' => sub {
    my @seen;
    DBIx::Squirrel->tap(
        sub { undef },
        sub (@v) { push @seen, [@v]; 0 },
        sub (@v) { push @seen, [@v]; '' },
        sub (@v) { push @seen, [@v] },
    );
    is \@seen, [[undef], [0], ['']];
};

subtest 'Stop ends the branch quietly' => sub {
    my %ways = (
        'fully qualified' => sub { DBIx::Squirrel::Stop() },
        'class method'    => sub { DBIx::Squirrel->Stop },
        'subclass method' => sub { My::Squirrel->Stop },
    );
    for my $way (sort keys %ways) {
        my @ran;
        my $result;
        ok lives {
            $result = DBIx::Squirrel->tap(
                sub { push @ran, 'a'; 1 },
                sub { push @ran, 'b'; $ways{$way}->(); push @ran, 'b-after' },
                sub { push @ran, 'c' },
            );
        }, "$way: doesn't die";
        is \@ran,   [qw(a b)],        "$way: later stages don't run";
        is $result, 'DBIx::Squirrel', "$way: returns the invocant";
    }
};

subtest 'a failing stage is named in the error' => sub {
    my $named   = "tap (#2: b) failed: boom\n";
    my $unnamed = "tap (#1) failed: boom\n";
    my @ran;
    like dies {
        DBIx::Squirrel->tap(
            sub { push @ran, 'a'; 1 },
            b => sub { die "boom\n" },
            sub { push @ran, 'c' },
        );
    }, qr/^\Q$named\E\s*\Q$here\E/x, 'named stage, reported at the caller';
    is \@ran, ['a'], "later stages don't run";

    like dies {
        DBIx::Squirrel->tap(sub { die "boom\n" });
    }, qr/^\Q$unnamed\E/x, 'unnamed stage';
};

subtest 'invalid stages fail before any stage runs' => sub {
    my @ran;
    like dies {
        DBIx::Squirrel->tap(sub { push @ran, 'a' }, 'b');
    }, qr/^\QExpected a code-reference to follow a non-reference $here\E/x;
    is \@ran, [], 'no stage ran';
};

subtest 'Stop outside a pipeline' => sub {
    my $error = dies { DBIx::Squirrel->Stop };
    isa_ok $error, ['DBIx::Squirrel::Stop'], 'dies with the Stop object';
    is "$error", "Stop used outside a pipeline\n", 'which explains itself';
};

done_testing;
