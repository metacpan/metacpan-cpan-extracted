#!perl

# Name: Array sorting
# Require: 4
# Desc:
#


require 'benchlib.pl';

@a = (1..200);
srand(10);
push(@b, splice(@a, rand(@a), 1)) while @a;  # shuffle

&runtest(0.5, <<'ENDTEST');

    @a = sort {$a <=> $b } @b;

ENDTEST
