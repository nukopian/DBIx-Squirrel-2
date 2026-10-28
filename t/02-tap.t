use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;

package My::Squirrel {
    our @ISA = 'DBIx::Squirrel';
}

my $here = 'at ' . __FILE__ . ' line';

subtest 'stages run in order, each given the invocant' => sub {
    my $self = bless {}, 'My::Squirrel';
    my @seen;
    my $result = $self->tap(
        sub ($s) { push @seen, ['a', $s] },
        b => sub ($s) { push @seen, ['b', $s] },
        sub ($s) { push @seen, ['c', $s] },
    );
    is \@seen, [
        ['a', exact_ref($self)],
        ['b', exact_ref($self)],
        ['c', exact_ref($self)],
    ];
    ref_is $result, $self, 'returns the invocant';
};

subtest 'as a class method' => sub {
    my @seen;
    my $result = DBIx::Squirrel->tap(sub ($s) {
        push @seen, $s;
    });
    is $result, 'DBIx::Squirrel',   'returns the class';
    is \@seen,  ['DBIx::Squirrel'], 'stages get the class';
};

subtest 'no stages' => sub {
    is DBIx::Squirrel->tap, 'DBIx::Squirrel', 'returns the invocant';
};

subtest 'what stages return is ignored' => sub {
    my @ran;
    DBIx::Squirrel->tap(
        sub { push @ran, 'a'; return },
        sub { push @ran, 'b'; return (undef,  'stop') },
        sub { push @ran, 'c'; return (0,      0) },
        sub { push @ran, 'd'; return ('row1', 'row2') },
        sub { push @ran, 'e' },
    );
    is \@ran, [qw(a b c d e)], 'every stage runs';
};

subtest 'Stop ends the stages quietly' => sub {
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
                sub { push @ran, 'a' },
                sub { push @ran, 'b'; $ways{$way}->(); push @ran, 'b-after' },
                sub { push @ran, 'c' },
            );
        }, "$way: doesn't die";
        is \@ran,   [qw(a b)],        "$way: later stages don't run";
        is $result, 'DBIx::Squirrel', "$way: returns the invocant";
    }
};

subtest 'a failing stage is named in the error' => sub {
    my $named   = "A tap stage (#2: b) failed: boom\n";
    my $unnamed = "A tap stage (#1) failed: boom\n";
    my @ran;
    like dies {
        DBIx::Squirrel->tap(
            sub { push @ran, 'a' },
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
