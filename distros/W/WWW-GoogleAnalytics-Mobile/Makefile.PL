use inc::Module::Install;
name 'WWW-GoogleAnalytics-Mobile';
all_from 'lib/WWW/GoogleAnalytics/Mobile.pm';

requires 'Furl', 0.31;
requires 'URI';
requires 'List::Util';
requires 'Net::DNS::Lite';
requires 'Digest::SHA';
requires 'Plack', 0.9963;
requires 'parent';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::TCP', 1.11;

auto_set_repository;
#auto_include;
WriteAll;
