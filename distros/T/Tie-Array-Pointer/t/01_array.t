use Test::More tests => 8;
use Tie::Array::Pointer;

my @pixel;

tie @pixel, 'Tie::Array::Pointer', {
  length => '256',
  type   => 'L',
};

ok(tied(@pixel), "Did the call to tie() succeed?");

ok(tied(@pixel)->address, "Do we have a non-NULL address?");

ok((scalar @pixel) == 256, "FETCHSIZE test");

eval {
  push @pixel, 1;
};
ok($@, "PUSH should've failed.  Did it?");

eval {
  unshift @pixel, 1;
};
ok($@, "I don't even want to think implementing UNSHIFT");

ok(exists($pixel[255]), "EXISTS check");

ok(! exists($pixel[256]), "bounds check");

$pixel[50] = 44;
ok($pixel[50] == 44, "STORE and FETCH test");
