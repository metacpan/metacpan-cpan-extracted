use strict;
use inc::Module::Install;

name 'URI-Escape-JavaScript';
all_from 'lib/URI/Escape/JavaScript.pm';
 
perl_version '5.008001';
build_requires 'Test::More';
requires 'Encode' => '2.12';

WriteAll;
