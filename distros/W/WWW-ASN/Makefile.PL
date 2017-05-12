use strict;
use warnings;
use inc::Module::Install;

name     'WWW-ASN';
all_from 'lib/WWW/ASN.pm';
license  'perl';

test_requires 'Test::More' => 0;
test_requires 'FindBin'    => 0;
test_requires 'File::Spec::Functions' => 0;

requires 'Moo'         => 1;
requires 'File::Slurp' => 0;
requires 'JSON'        => 0;
requires 'XML::Twig'   => 0;
requires 'LWP::Simple' => 0;
requires 'URI'         => 0;

auto_set_repository;
auto_install;
WriteAll;

