#!/usr/local/bin/perl

use strict;
use inc::Module::Install;

name        'Test-Signature';
all_from    'lib/Test/Signature.pm';

requires    'Test::Builder' => '0.17';
requires    'Test::More'    => '0.47';

auto_provides;

sign; WriteAll;
