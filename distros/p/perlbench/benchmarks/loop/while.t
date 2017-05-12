#!perl

# Name: A simple while loop
# Require: 4
# Desc:
#


require 'benchlib.pl';

&runtest(0.007, <<'ENDTEST');

    $count = 30000;
    while ($count--) {
	$foo = $count;
    }

ENDTEST
