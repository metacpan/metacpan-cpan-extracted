use strict;
use warnings;
use inc::Module::Install;
use 5.008005;

name 'VSO';
perl_version '5.008001';
license 'perl';
all_from 'lib/VSO.pm';

test_requires 'Test::More'  => '0';

requires 'Carp' => '0';
requires 'Scalar::Util' => 0;

tests_recursive();
WriteAll();

