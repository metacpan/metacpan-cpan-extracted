use strict;
use warnings;

use Test::More tests => 4;

use Test::Stub qw(stub);

{
  package Target;

  sub new { bless \(do { my $x = shift }) }

  sub something { 'an apple!' }
  sub somewhere { 'upstairs!' }
}

sub lame_try (&) {
  my $code = shift;
  local $@;
  eval { $code->() };
  return $@;
}

my $target1 = Target->new;
my $target2 = Target->new;

stub($target1)->something('a banana?');
stub($target2)->somewhere('outside??');

is( $target1->something, 'a banana?', 'stubbed-out method on $target1 behaves correctly' );
is( $target2->somewhere, 'outside??', 'stubbed-out method on $target2 behaves correctly' );

# Here's an interesting question: what should $target1->somewhere return: 'upstairs!' or 'outside??' ?
# I haven't attempted to answer that question, instead this test simply shows the current behavior
# (which is that $target1->somewhere ne $target2->somewhere).
is( $target1->somewhere, 'upstairs!', 'stubbing out methods on some other instance of Target did not affect existing instances of Target' );
is( $target2->something, 'an apple!', 'stubbing out methods on a new instance of Target did not inherit stubbed-out methods on pre-existing instances' );

