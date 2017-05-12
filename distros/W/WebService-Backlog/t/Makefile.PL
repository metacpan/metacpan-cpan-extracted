use inc::Module::Install;
name 'WebService-Backlog';
all_from 'lib/WebService/Backlog.pm';

requires 'Class::Accessor::Fast';
requires 'Carp';
requires 'RPC::XML';
requires 'Crypt::SSLeay';

build_requires 'Test::More';

use_test_base;
auto_include;
WriteAll;
