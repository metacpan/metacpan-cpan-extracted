#!perl -T
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/03-*tempfile-preserve.t" -*-

use strict;
use warnings;

our ($strategy, $class);
$strategy = 'tempfile-preserve';
$class = 'Test::Trap::Builder::TempFile';

use lib '.';
require 't/03-files.pl';
