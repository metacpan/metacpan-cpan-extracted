#!perl

# Name: for (1 .. 10_000) loop
# Require: 4
# Desc:
#


require 'benchlib.pl';

&runtest(0.02, <<'ENDTEST');

    for (1 .. 10_000) {
	$foo = $_;
    }

ENDTEST
