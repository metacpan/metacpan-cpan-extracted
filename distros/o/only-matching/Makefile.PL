use strict;
use inc::Module::Install;

name           'only-matching';
all_from       'lib/only/matching.pm';
build_requires 'Test::More' => '0.47';

WriteAll;
