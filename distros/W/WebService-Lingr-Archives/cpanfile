requires 'perl', '5.010';
requires 'LWP::UserAgent', '0';
requires 'JSON', '2.53';
requires 'URI',  '1.59';
requires "Carp";

on test => sub {
    requires 'Test::Exception',    '0.31';
    requires 'Test::MockObject',   '1.20120301';
    requires 'Test::More',         '0.98';
    requires 'Try::Tiny',          '0.16';
    requires "lib";
    requires "List::Util";
    requires "Exporter";
};

on 'configure' => sub {
    requires 'Module::Build', '0.42';
    requires 'Module::Build::Prereqs::FromCPANfile', "0.02";
};
