#!perl -T
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/03-*systemsafe.t" -*-

use strict;
use warnings;

our $strategy;
$strategy = 'SystemSafe';

use lib '.';
require 't/03-files.pl';
