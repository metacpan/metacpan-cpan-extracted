use inc::Module::Install;
name 'Test-Perl-Metrics-Simple';
all_from 'lib/Test/Perl/Metrics/Simple.pm';

requires $_ for (qw/Perl::Metrics::Simple Test::Builder/);

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
