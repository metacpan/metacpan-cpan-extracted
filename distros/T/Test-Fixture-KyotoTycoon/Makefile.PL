use inc::Module::Install;
name 'Test-Fixture-KyotoTycoon';
all_from 'lib/Test/Fixture/KyotoTycoon.pm';

requires
	'Cache::KyotoTycoon' => '0.12',
	'YAML::XS'           => '0.38',
	'Kwalify'            => '1.21',
	'parent'             => '0.225',
;

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;

install_script "bin/make_kt_fixture";

WriteAll;
