sub auto_set_repository { }

use inc::Module::Install;
name 'Text-MicroTemplate-Extended';
all_from 'lib/Text/MicroTemplate/Extended.pm';

requires 'Text::MicroTemplate' => '0.18';

test_requires 'Test::More' => '0.94';
use_test_base;

auto_set_repository;

WriteAll;
