use Test::Given;
use strict;
use warnings;

my @steps = ();
sub step($) { push @steps, @_ }
describe 'Order in context' => sub {
  onDone sub { step 'D1' };
  And sub { step 'd1' };
  Given sub { step 'G1' };
  And   sub { step 'g1' };
  When sub { step 'W1' };
  And  sub { step 'w1' };
  Invariant sub { step 'I1' };
  And sub { step 'i1' };
  Then sub { step 'T0' };
  And  sub { step 't0' };
  Invariant sub { step 'I2' };
  And sub { step 'i2' };
  When sub { step 'W2' };
  And  sub { step 'w2' };
  Given sub { step 'G2' };
  And   sub { step 'g2' };
  onDone sub { step 'D2' };
  And sub { step 'd2' };
};
onDone sub { print '### ORDER:', join(',', @steps) };
