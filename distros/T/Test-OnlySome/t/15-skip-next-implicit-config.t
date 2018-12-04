#!perl
use rlib 'lib';
use DTest;
use Test::OnlySome;

is($TEST_NUMBER_OS, 1, 'Tests start at 1');

os ok(1, 'Test 1');     # This one should run

is($TEST_NUMBER_OS, 2, '$TEST_NUMBER_OS increments to 2');

skip_next ;
os ok(0, 'Test 2 - should be skipped');

is($TEST_NUMBER_OS, 3, '$TEST_NUMBER_OS increments to 3');

os ok(1, 'Test 3');     # This one should run

is($TEST_NUMBER_OS, 4, '$TEST_NUMBER_OS increments to 4');

skip_next ;
os ok(0, 'Test 4 - should be skipped');

is($TEST_NUMBER_OS, 5, '$TEST_NUMBER_OS increments to 5');

os ok(1, 'Test 5');     # This one should run

is($TEST_NUMBER_OS, 6, '$TEST_NUMBER_OS increments to 6');

$TEST_ONLYSOME->{n} = 2;
skip_next ;
os {
    ok(0, 'Test 6');
    ok(0, 'Test 7');
};

is($TEST_NUMBER_OS, 8, '$TEST_NUMBER_OS increments to 8');

ok(1, 'Test 9');

is_deeply($TEST_ONLYSOME, {skip => {2=>true, 4=>true, 6=>true}, verbose=>0, n=>2},
    '$TEST_ONLYSOME is what we set');

done_testing();
