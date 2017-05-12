#!perl

# Name: Mixed arithmetics
# Require: 4
# Desc:

require 'benchlib.pl';

$x = 0;

&runtest(20, <<'ENDTEST');

    $x = ($x + 2) % 333;
    $z = $x / 40;
    $y = $x * 40580;
    $x = 3;
    $x++;
    $x++;
    $x = $x + 1900.3;
    $x = $x + 1900.3;
    $x -= 1;

ENDTEST
