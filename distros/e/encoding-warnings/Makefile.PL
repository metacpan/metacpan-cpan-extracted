#!/usr/bin/perl

use strict;
use inc::Module::Install;

name        'encoding-warnings';
author	    'Audrey Tang <cpan@audreyt.org>';
all_from    'lib/encoding/warnings.pm';

sign; WriteAll;
