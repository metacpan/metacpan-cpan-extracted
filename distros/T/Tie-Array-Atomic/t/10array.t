# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { plan tests => 8 };
use bytes;
use strict;
use Tie::Array::Atomic;

sub store_load_sv_test {
  tie my @buffer, 'Tie::Array::Atomic', { length => 2, type   => 'a2' };
  $buffer[0] = "AB";
  $buffer[1] = "BC";
            
  return (($buffer[0] eq "AB") && ($buffer[1] eq "BC"));
}

sub store_load_uint_test {
  tie my @buffer, 'Tie::Array::Atomic', { length => 2, type   => 'L' };
  $buffer[0] = 1;
  $buffer[1] = 2;
            
  return (($buffer[0] == 1) && ($buffer[1] == 2));
}

sub store_load_sint_test {
  tie my @buffer, 'Tie::Array::Atomic', { length => 2, type   => 'l' };
  $buffer[0] = -1;
  $buffer[1] = -2;
            
  return (($buffer[0] == -1) && ($buffer[1] == -2));
}

sub add_sint_test {
  tie my @buffer, 'Tie::Array::Atomic', { length => 1, type   => 'L' };
  $buffer[0] = 0;
  tied(@buffer)->add(0, 1);
            
  return ($buffer[0] == 1);
}

sub sub_sint_test {
  tie my @buffer, 'Tie::Array::Atomic', { length => 1, type   => 'l' };
  $buffer[0] = 0;
  tied(@buffer)->sub(0, 1);
            
  return ($buffer[0] == -1);
}

sub and_sint_test {
  tie my @buffer, 'Tie::Array::Atomic', { length => 1, type   => 'L' };
  $buffer[0] = 0;
  tied(@buffer)->and(0, 1);
            
  return ($buffer[0] == 0);
}

sub or_sint_test {
  tie my @buffer, 'Tie::Array::Atomic', { length => 1, type   => 'L' };
  $buffer[0] = 0;
  tied(@buffer)->or(0, 1);
            
  return ($buffer[0] == 1);
}

sub xor_sint_test {
  tie my @buffer, 'Tie::Array::Atomic', { length => 1, type   => 'L' };
  $buffer[0] = 1;
  tied(@buffer)->xor(0, 1);
            
  return ($buffer[0] == 0);
}


# 1
ok(store_load_sv_test());
ok(store_load_uint_test());
ok(store_load_sint_test());
ok(add_sint_test());
ok(sub_sint_test());
ok(and_sint_test());
ok(or_sint_test());
ok(xor_sint_test());


