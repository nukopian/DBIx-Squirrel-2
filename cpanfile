requires 'perl', '5.036';
requires 'DBI';

on test => sub {
    requires 'DBD::SQLite';
    requires 'Test2::V0';
    requires 'Test2::Plugin::NoWarnings';
};

on develop => sub {
    requires 'Data::Dump';
    requires 'Perl::Critic';
    requires 'Perl::Tidy';
    requires 'Test2::Harness';
};
