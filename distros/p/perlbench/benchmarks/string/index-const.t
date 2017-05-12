#!perl

# Name: Searching for fixed strings using index()
# Require: 4
# Desc:
#


require 'benchlib.pl';

$a = "xx" x 100;

&runtest(25, <<'ENDTEST');

   $c = index($a, "foobar");
   $c = index($a, "xxx");

   $c = index($a, "foobar");
   $c = index($a, "xxx");

ENDTEST
