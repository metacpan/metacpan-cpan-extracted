use inc::Module::Install;
name 'Test-Fixture-DBIxSkinny';
all_from 'lib/Test/Fixture/DBIxSkinny.pm';

requires 'Kwalify' => 1.16;
requires 'DBIx::Skinny' => 0.04;
requires 'YAML::Syck' => 1.00;
requires 'Params::Validate' => 0.89;

test_requires 'Test::Requires';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';

auto_set_repository;
auto_include;
WriteAll;
