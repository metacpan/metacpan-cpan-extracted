use strict; use warnings;
use Test::More tests => 5;
use Tie::Hash::StructKeyed;

# hakim@fotango.com 14 April 2005

diag "Behaviour of objects in keys is undefined and subject to change";
# (These tests, and the TODO tests here, represent how I am currently viewing
# the end goal, but are for guideline only, as this is may change).

tie my %hash, 'Tie::Hash::StructKeyed';

my $x = bless [1,2,3], 'Fake::Object::Cow';
my $y = bless [1,2,3], 'Fake::Object::Sheep';
my $z  = bless [2,3,4], 'Fake::Object::Sheep';
my $zz = bless [2,3,4], 'Fake::Object::Sheep';

sub Fake::Object::Sheep::baa {
  my $self = shift;
  $self->[0]++;
}

$hash{$x} =   "X";
$hash{$y} =   "Y";
$hash{$z} =   "Z";
$hash{$zz} = "ZZ";

is ($hash{$x}, 'X',  'Simple object key test');
is ($hash{$y}, 'Y',  'Simple object key test');

TODO: {
  local $TODO = 'Separate objects with different representations should not hash the same';
  is ($hash{$z}, 'Z',  'Multiple object test');
}
is ($hash{$zz}, 'ZZ',  'Simple object key test');

TODO: {
  local $TODO = 'Same object after state change should hash the same';
  $zz->baa;
  is($hash{$zz}, 'ZZ', 'Same object after state change');
}

