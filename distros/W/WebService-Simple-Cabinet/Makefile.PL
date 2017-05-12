use inc::Module::Install;
name 'WebService-Simple-Cabinet';
all_from 'lib/WebService/Simple/Cabinet.pm';

requires $_ for (qw/
    WebService::Simple
    UNIVERSAL::require
/);

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
