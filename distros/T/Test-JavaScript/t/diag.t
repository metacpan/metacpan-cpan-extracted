#!/usr/bin/perl

use strict;
use warnings;

use lib "t/lib";
require Test::Simple::Catch;
my($out, $err) = Test::Simple::Catch::caught();
local $ENV{HARNESS_ACTIVE} = 0;

use Test::More tests => 4;
use Test::JavaScript;

js_ok("diag('Hello World');", "Warn hello");
print $out->read;

my $warn = $err->read;
chomp $warn;

is($warn,"# Hello World", "warned $warn");
print $out->read;
	
js_ok("var myval = 3; diag('the variable myval is ' + myval)", "run diag");
print $out->read;

is($err->read, "# the variable myval is 3\n", "# the variable myval is 3");
print $out->read;
print $err->read;
