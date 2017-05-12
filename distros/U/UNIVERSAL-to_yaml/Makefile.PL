use strict;
use warnings;
use inc::Module::Install;

name 'UNIVERSAL-to_yaml';
all_from 'lib/UNIVERSAL/to_yaml.pm';

requires(YAML => '1.15');

build_requires 'Test::More' => 0;

author_tests("xt");

WriteMakefile;

