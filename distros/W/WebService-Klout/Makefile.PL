use strict;
use warnings;
use inc::Module::Install;

name     'WebService-Klout';
all_from 'lib/WebService/Klout.pm';
author   'Craftworks <craftwork at cpan.org>';
license  'perl';

requires 'LWP::UserAgent';
requires 'JSON';

test_requires 'Test::More' => 0.96;

auto_install;

WriteAll;
