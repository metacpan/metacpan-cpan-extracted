use 5.012;
use warnings;
use lib 't';
use MyTest;

cmp_deeply(MyTest::Container::std_vector_int([1,2,3,4,5]), [1,2,3,4,5]);

cmp_deeply(MyTest::Container::std_map_string_int({a => 1, b => 2, c => 3}), {a => 1, b => 2, c => 3});

cmp_deeply(MyTest::Container::std_map_int_bool({1 => 0, 2 => 1, 3 => 0, 4 => 1}), {'1' => 0, '2' => 1, '3' => 0, '4' => 1});

done_testing();