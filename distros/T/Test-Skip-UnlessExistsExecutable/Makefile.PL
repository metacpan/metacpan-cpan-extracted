sub author_tests        { }
sub auto_set_repository { }

use inc::Module::Install;
name 'Test-Skip-UnlessExistsExecutable';
all_from 'lib/Test/Skip/UnlessExistsExecutable.pm';

requires( 'File::Which' => 1.09, );
build_requires 'Test::More';

tests('t/*.t');
author_tests('xt');

use_test_base;
auto_include;
auto_set_repository;
WriteAll;
