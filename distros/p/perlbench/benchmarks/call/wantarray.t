#!perl

# Name: Calling procedures with return value
# Require: 5
# Desc:
#


require 'benchlib.pl';

sub foo
{
    my @ret = (1, 2, @_);
    wantarray ? @ret : \@ret;
}

&runtest(5, <<'ENDTEST');

   my $foo;
   my @foo;

   $foo = foo();
   $foo = foo(33);

   @foo = foo;

ENDTEST
