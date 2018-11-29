#!perl
# 06-multi-package.t: Use Test::OnlySome from multiple packages in the same
# file and make sure that their variables are independent.

package P1;

use rlib 'lib';
use DTest;
use Test::OnlySome;

package P2;

use rlib 'lib';
use DTest;
use Test::OnlySome;

package P1;

skip_these 2, 3;
os ok(1, 'P1 Test 1');
os ok(0, 'P1 Test 2 - skipped');
os ok(0, 'P1 Test 3 - skipped');
os ok(1, 'P1 Test 1');
is($TEST_NUMBER_OS, 5, 'P1 $TEST_NUMBER_OS increments to 5');

package P2;

# Make sure our counter is different from P1's
is($TEST_NUMBER_OS, 1, 'P2 $TEST_NUMBER_OS starts at 1');

# Make sure the skips from P1 aren't affecting us
os ok(1, 'P2 Test 1');
os ok(1, 'P2 Test 2');
os ok(1, 'P2 Test 3');
os ok(1, 'P2 Test 4');

skip_next;
os ok(0, 'P2 Test 5 - skipped');

is($TEST_NUMBER_OS, 6, 'P2 $TEST_NUMBER_OS increments to 6');

package P1;

is($TEST_NUMBER_OS, 5, 'P1 $TEST_NUMBER_OS is still 5');
os ok(1, 'P1 Test 5');
os ok(1, 'P1 Test 6');
is($TEST_NUMBER_OS, 7, 'P1 $TEST_NUMBER_OS increments to 7');

done_testing();
