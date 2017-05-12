use strictures 1;
use Test::More;

my $x = eval "sub (frew) { 1 }";
ok !ref $x, 'correctly "dies" with bad prototype';

done_testing;
