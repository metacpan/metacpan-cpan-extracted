use inc::Module::Install;
name 'Text-Template-Compact';
requires( perl => '5.8.3' );

license 'perl';
all_from 'lib/Text/Template/Compact.pm';
build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
WriteAll;
