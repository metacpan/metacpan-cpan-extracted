#!perl

# Name: Calling recursive procedures
# Require: 5
# Desc:
#



require 'benchlib.pl';

# for some non-obvious reason, this code does not work with perl4
# probably just a bug.

sub fib {
    $_[0] < 2 ? 1 : &fib($_[0] - 2) + &fib($_[0] - 1);
}

&runtest(0.01, <<'ENDTEST');

   $f = &fib(17);

ENDTEST
