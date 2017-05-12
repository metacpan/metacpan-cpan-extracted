#!perl

# Name: Calling procedures without arguments
# Require: 4
# Desc:
#


require 'benchlib.pl';

sub foo {}
sub bar {}


&runtest(20, <<'ENDTEST');

   &foo;
   &bar;
   &foo;
   &bar;
   &foo;
   &bar;

ENDTEST
