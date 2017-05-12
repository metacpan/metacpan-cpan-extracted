use strict;
use warnings;
use inc::Module::Install;
use 5.008005;

name 'WWW-Virull';
perl_version '5.008001';
license 'perl';
all_from 'lib/WWW/Virull.pm';

test_requires 'LWP::UserAgent';
test_requires 'Test::More'  => '0.77';

tests_recursive();
WriteAll();

