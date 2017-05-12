use strict;
use inc::Module::Install;

name           'Test-File-Cleaner';
all_from       'lib/Test/File/Cleaner.pm';
requires       'Carp'             => 0;
requires       'File::Spec'       => '0.82';
requires       'File::stat'       => 0;
requires       'File::Basename'   => 0;
requires       'File::Find::Rule' => '0.02';
build_requires 'Test::More'       => '0.47';

WriteAll;
