use inc::Module::Install;
use Module::Install::AuthorTests;

name 'WWW-Google-ClientLogin';
all_from 'lib/WWW/Google/ClientLogin.pm';

requires 'Carp';
requires 'LWP::UserAgent';
requires 'LWP::Protocol::https';
requires 'HTTP::Request::Common';
requires 'parent';

test_requires 'Test::More', 0.98;
test_requires 'Test::Fake::HTTPD', 0.03;
test_requires 'Test::SharedFork', 0.18;
test_requires 'Test::Flatten', 0.06;
test_requires 'URI::Escape';

tests join q{ }, map { sprintf 't%s.t', '/*' x $_ } 1..3;
author_tests 'xt';

repository 'http://github.com/xaicron/p5-WWW-Google-ClientLogin/';
bugtracker 'http://github.com/xaicron/p5-WWW-Google-ClientLogin/issues';

WriteAll;
