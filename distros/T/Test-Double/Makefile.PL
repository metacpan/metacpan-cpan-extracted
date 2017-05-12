use inc::Module::Install;

name 'Test-Double';
license 'perl';
all_from 'lib/Test/Double.pm';
readme_pod_from 'lib/Test/Double.pm';

requires 'Exporter';
requires 'Class::Monadic';
requires 'Scalar::Util', '1.14';
requires 'List::MoreUtils';
requires 'Test::Deep';
requires 'Test::More', '0.96';

tests 't/*.t t/*/*.t';
test_requires 'Test::More', '0.96';
test_requires 'Test::Tester';

author_tests 'xt';

auto_set_repository;
WriteAll;
