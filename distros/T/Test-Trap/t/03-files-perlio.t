#!perl -T
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/03-*perlio.t" -*-

use strict;
use warnings;

our $strategy;
$strategy = 'PerlIO';

use lib '.';
require 't/03-files.pl';
