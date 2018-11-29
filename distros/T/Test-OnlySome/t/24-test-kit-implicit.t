#!perl
# 24-test-kit-implicit.t: A selection of tests 01-19, but using a packaged
# Test::Kit to grab Test::OnlySome, and using implicit config

package t24;
use rlib 'lib';
use DTest;
use DTestKit;
use Data::Dumper;

# 01 {{{1
# Vars to hold the debug output from os(), since os() processing happens
# at compile time, and the stack trace doesn't point us here.
our ($t1, $t2);

os 't24::t1' my $a1;
is($t1->{code}, 'my $a1;', 'os() grabs a statement');

os 't24::t2' {my $a2; my $b2;};
is($t2->{code}, '{my $a2; my $b2;}', 'os() grabs a block');

BEGIN {
    eval { local $SIG{'__DIE__'}; os my $a3; };
    ok(!$@, 'os() with statement, without debug, succeeded');
}

BEGIN {
    eval { local $SIG{'__DIE__'}; os {my $a4; my $b4;}; };
    ok(!$@, 'os() with block, without debug, succeeded');
}

# }}}1

is($TEST_NUMBER_OS, 5, 'TEST_NUMBER_OS increments');

# 02 {{{1
$TEST_ONLYSOME->{skip} = { 6=>true, 8=>true };

os ok(1, 'Test 5');     # This one should run

is($TEST_NUMBER_OS, 6, '$TEST_NUMBER_OS increments to 6');

os ok(0, 'Test 6 - should be skipped');

is($TEST_NUMBER_OS, 7, '$TEST_NUMBER_OS increments to 7');

os ok(1, 'Test 7');     # This one should run

is($TEST_NUMBER_OS, 8, '$TEST_NUMBER_OS increments to 8');

os ok(0, 'Test 8 - should be skipped');

is($TEST_NUMBER_OS, 9, '$TEST_NUMBER_OS increments to 9');

# }}}1

# 03 {{{1

$TEST_ONLYSOME->{skip}->{10} = true;
$TEST_ONLYSOME->{skip}->{14} = true;

os ok(1, 'Test 9');     # This one should run

$TEST_ONLYSOME->{n} = 2;
os {
    ok(0, 'Test 10 - should be skipped');
    ok(0, 'Test 11 - should be skipped');
}

is($TEST_NUMBER_OS, 12, '$TEST_NUMBER_OS increments to 12');

os {
    ok(1, 'Test 12');
    ok(1, 'Test 13');
}

is($TEST_NUMBER_OS, 14, '$TEST_NUMBER_OS increments to 14');

$TEST_ONLYSOME->{n} = 3;
os {
    ok(0, 'Test 14 - should be skipped');
    ok(0, 'Test 15 - should be skipped');
    ok(0, 'Test 16 - should be skipped');
}

is($TEST_NUMBER_OS, 17, '$TEST_NUMBER_OS increments to 17');

$TEST_ONLYSOME->{n} = 1;
# }}}1

# 04 {{{1

skip_these 18, 19;

os ok(1, 'Test 17');     # This one should run
os ok(0, 'Test 18 - should be skipped');
os ok(0, 'Test 19 - should be skipped');
os ok(1, 'Test 20');     # This one should run

is($TEST_NUMBER_OS, 21, '$TEST_NUMBER_OS increments to 21');

is_deeply($TEST_ONLYSOME, {skip => {6=>true, 8=>true, 10=>true, 14=>true, 18=>true,
                                19=>true}, n=>1},
    '$TEST_ONLYSOME is what we set');

# }}}1

# 05 {{{1

os ok(1, 'Test 21');     # This one should run
skip_next;
os ok(0, 'Test 22 - should be skipped');
is($TEST_NUMBER_OS, 23, '$TEST_NUMBER_OS increments to 23');

os ok(1, 'Test 23');     # This one should run

is($TEST_ONLYSOME->{skip}->{22}, true, 'skip->22 is set');

# }}}1

done_testing();
# vi: set fdm=marker:
