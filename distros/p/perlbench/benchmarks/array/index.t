#!perl

# Name: Index arrays
# Require: 4
# Desc:
#


require 'benchlib.pl';

@a = (1..1000);

&runtest(20, <<'ENDTEST');

   $a = $a[0] + $a[534];
   $a = $a[1] + $a[535];
   $a = $a[2] + $a[536];
   $a = $a[3] + $a[537];

   $a[500] = $a[200];
   $a[501] = $a[201];
   $a[502] = $a[202];
   $a[503] = $a[203];

ENDTEST
