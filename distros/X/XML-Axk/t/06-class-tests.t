#!perl
# 06-class-tests.t: Run t/tests

use 5.020;
use strict;
use warnings;
use rlib;
use Test::Class::Load (rlib::_dirs('tests'));
Test::Class->runtests;

# vi: set ts=4 sts=4 sw=4 et ai fdm=marker fdl=1: #
