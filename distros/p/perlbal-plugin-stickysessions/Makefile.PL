use inc::Module::Install;
name 'Perlbal-Plugin-StickySessions';
all_from 'lib/Perlbal/Plugin/StickySessions.pm';

build_requires 'Test::More';
build_requires 'Test::Declare';

use_test_base;
auto_include;
WriteAll;
