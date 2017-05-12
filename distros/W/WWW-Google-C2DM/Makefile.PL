use inc::Module::Install;
use Module::Install::AuthorTests;

name 'WWW-Google-C2DM';
all_from 'lib/WWW/Google/C2DM.pm';

requires 'HTTP::Request';
requires 'LWP::UserAgent';
requires 'LWP::Protocol::https';
requires 'parent';
recommends 'WWW::Google::ClientLogin';

test_requires 'Test::More', 0.98;
test_requires 'Test::Flatten', 0.07;
test_requires 'Test::Fake::HTTPD', 0.03;
test_requires 'Test::SharedFork', 0.19;

tests join q{ }, map { sprintf 't%s.t', '/*' x $_ } 1..3;
author_tests 'xt';

repository 'http://github.com/xaicron/p5-WWW-Google-C2DM/';
bugtracker 'http://github.com/xaicron/p5-WWW-Google-C2DM/issues';

WriteAll;
