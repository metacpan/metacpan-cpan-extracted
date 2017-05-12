use strictures 1;
use Test::More;
no warnings::illegalproto;

my $x = eval "sub (frew) { 1 }";
is 1, $x->(), 'does not die on "bad" prototype';

eval 'my $f = (undef) . "foo"';
like $@, qr/uninitialized/, 'does not override uninitialized warnings';

eval 'my $f = 5 + "foo"';
like $@, qr/numeric/, 'does not override numeric warnings';

done_testing;
