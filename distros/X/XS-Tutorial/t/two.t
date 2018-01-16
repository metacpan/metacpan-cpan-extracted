use Test::More;

BEGIN { use_ok 'XS::Tutorial::Two' }

cmp_ok XS::Tutorial::Two::add_ints(7,3), '==', 10;
cmp_ok XS::Tutorial::Two::add_ints(1500, 21000, -1000), '==', 21500;
ok !defined XS::Tutorial::Two::add_ints(), 'empty list returns undef';

done_testing;
