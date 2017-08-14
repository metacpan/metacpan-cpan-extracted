#!/usr/bin/perl
#-I/home/phil/z/perl/cpan/UnicodeOperators/lib
#-------------------------------------------------------------------------------
# Test unicode operators
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------

require v5.16;
use warnings FATAL => qw(all);
use strict;
use Test::More tests=>3;
use UnicodeOperators;

ok [0..2]∙[2] == 2;
ok {a►1, b►2, c►3}∙{a} eq 1;
ok "aaa" ○ s/a/b/gsr eq 'bbb';
