#!/usr/bin/perl -I/home/phil/perl/cpan/NasmX86/lib -I/home/phil/perl/cpan/UnisynParse/lib
#-------------------------------------------------------------------------------
# Test Unisyn::Parse
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc, 2016-2021
#-------------------------------------------------------------------------------
use warnings FATAL => qw(all);
use strict;
use Unisyn::Parse;

Unisyn::Parse::test();
