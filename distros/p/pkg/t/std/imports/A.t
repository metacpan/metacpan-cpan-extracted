#!perl

use Test::Lib;

sub PKG () { 'A' }
our $PKG = PKG;

require std::imports::pkg;
