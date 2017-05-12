use strict;
use warnings;
use inc::Module::Install;

requires 'File::Spec';
requires 'Test::More' => '0.47';
requires 'Test::UseAllModules' => '0.10';

WriteAll;
