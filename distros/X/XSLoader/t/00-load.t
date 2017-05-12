#!perl -wT
use strict;
use Test::More tests => 1;

my $module = "XSLoader";
use_ok($module);
diag "testing $module v".$module->VERSION." under Perl $]";
