#!/usr/bin/perl

use strict;
use inc::Module::Install;

name     'Tie-Discovery';
all_from 'lib/Tie/Discovery.pm';

sign; WriteAll;
