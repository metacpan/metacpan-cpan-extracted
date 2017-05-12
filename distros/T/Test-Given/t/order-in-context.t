use Test::Given;
require 't/test_helper.pl';
use strict;
use warnings;

our ($lines);

describe 'Order of execution within context' => sub {
  Given lines => sub { run_spec('t/t/order-in-context.t') };
  Invariant sub { contains($lines, qr/All tests successful/) };
  Then sub { contains($lines, qr/ORDER:G1,g1,G2,g2,W1,w1,W2,w2,T0,t0,I1,i1,I2,i2,D1,d1,D2,d2\b/) };
};
