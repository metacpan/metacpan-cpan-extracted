use inc::Module::Install;
name 'Test-Mock-ExternalCommand';
all_from             'lib/Test/Mock/ExternalCommand.pm';
readme_from          'lib/Test/Mock/ExternalCommand.pm';
readme_markdown_from 'lib/Test/Mock/ExternalCommand.pm';
readme_pod_from      'lib/Test/Mock/ExternalCommand.pm';

githubmeta;

requires 'Variable::Expand::AnyLevel';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Capture::Tiny';

auto_set_repository;
#auto_include;
WriteAll;
