#!/usr/bin/perl

use strict;
use Config;
use inc::Module::Install;

name            'Win32-Hardlink';
all_from        'lib/Win32/Hardlink.pm';
include_deps    'Test::More';
makemaker_args  'OBJECT' => join(' ', map { "$_$Config{obj_ext}" } qw(Hardlink lnw));
auto_provides;

sign; WriteAll;

1;
