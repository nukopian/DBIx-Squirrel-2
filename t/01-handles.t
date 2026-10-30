use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;

package My::Squirrel {
    our @ISA = 'DBIx::Squirrel';
}

package My::Squirrel::db {    ## no critic (Modules::ProhibitMultiplePackages)
    our @ISA = 'DBIx::Squirrel::db';
}

package My::Squirrel::st {    ## no critic (Modules::ProhibitMultiplePackages)
    our @ISA = 'DBIx::Squirrel::st';
}

my @source = ('dbi:SQLite:dbname=:memory:', '', '', {RaiseError => 1});

subtest 'connect returns DBIx::Squirrel handles' => sub {
    my $dbh = DBIx::Squirrel->connect(@source);
    isa_ok $dbh, ['DBIx::Squirrel::db', 'DBI::db'], 'a database handle';
    isa_ok $dbh->prepare('SELECT 1'), ['DBIx::Squirrel::st', 'DBI::st'],
        'a statement handle';
    isa_ok DBIx::Squirrel->connect($dbh), ['DBIx::Squirrel::db'],
        'a clone of a database handle';
};

subtest "a subclass's own handle classes" => sub {
    my $dbh = My::Squirrel->connect(@source);
    isa_ok $dbh, ['My::Squirrel::db', 'DBIx::Squirrel::db'],
        'a database handle';
    isa_ok $dbh->prepare('SELECT 1'),
        ['My::Squirrel::st', 'DBIx::Squirrel::st'],
        'a statement handle';
};

done_testing;
