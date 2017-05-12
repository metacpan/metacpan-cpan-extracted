use inc::Module::Install;
name 'WWW-Shorten-Google';
all_from        'lib/WWW/Shorten/Google.pm';
readme_from     'lib/WWW/Shorten/Google.pm';
readme_pod_from 'lib/WWW/Shorten/Google.pm';

requires 'WWW::Shorten';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_include;

githubmeta;
auto_set_repository;

WriteAll;
