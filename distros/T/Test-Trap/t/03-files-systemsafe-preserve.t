#!perl -T
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/03-*systemsafe-preserve.t" -*-

use strict;
use warnings;

our ($strategy, $class);
$strategy = 'systemsafe-preserve';
$class = 'Test::Trap::Builder::SystemSafe';

use lib '.';
require 't/03-files.pl';
