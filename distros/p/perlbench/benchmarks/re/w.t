#!perl

# Name: Regexp matching /(\w+)/
# Require: 4
# Desc:
#


require 'benchlib.pl';

$a = ("-" x 100) . "foo" . ("-" x 100);

&runtest(15, <<'ENDTEST');

   $a =~ /(\w+)/;
   $a =~ /(\w+)/;

ENDTEST
