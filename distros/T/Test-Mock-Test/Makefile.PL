use inc::Module::Install;

name     'Test-Mock-Test';
all_from 'lib/Test/Mock/Test.pm';

author_requires 'Module::Install::AuthorTests';
author_tests('xt');

test_requires  'Test::More' => 0.88;
test_requires  'Test::Deep';

build_requires 'Test::More' => 0.88;

auto_install;

repository 'git://github.com/renormalist/test-mock-test.git';
bugtracker 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Mock-Test';

WriteAll;

