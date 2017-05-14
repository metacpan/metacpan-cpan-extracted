use Test::More;

BEGIN { use_ok 'XS::Tutorial::One' }

ok my $rand = XS::Tutorial::One::rand(), 'rand()';
like $rand, qr/^\d+$/, 'rand() returns a number';

ok !defined XS::Tutorial::One::srand(5), 'srand()';
ok $rand ne XS::Tutorial::One::rand(), 'after srand, rand returns different number';

done_testing;
