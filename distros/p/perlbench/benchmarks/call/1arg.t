#!perl

# Name: Calling procedures
# Require: 4
# Desc:
#


require 'benchlib.pl';

sub foo
{
    $_[0] * 2;
}

&runtest(25, <<'ENDTEST');

   &foo(3);
   &foo(5);
   &foo(8);

ENDTEST
