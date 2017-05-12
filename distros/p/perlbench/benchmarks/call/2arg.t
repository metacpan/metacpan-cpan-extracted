#!perl

# Name: Calling procedures
# Require: 4
# Desc:
#


require 'benchlib.pl';

sub foo
{
    $_[0] * $_[1];
}

&runtest(25, <<'ENDTEST');

   &foo(3, 4);
   &foo(5, 6);
   &foo(8, 9);

ENDTEST
