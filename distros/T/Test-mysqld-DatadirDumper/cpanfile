requires 'Class::Accessor::Lite';
requires 'DBI';
requires 'DBIx::FixtureLoader';
requires 'Test::mysqld';
requires 'perl', '5.008001';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'File::Temp';
    requires 'Test::More', '0.98';
};
