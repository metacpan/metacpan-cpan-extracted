#!perl
# 21-import-into.t: A selection of tests 01-19, but using a packaged
# Import::Into to grab Test::OnlySome
package t21;

use rlib 'lib';
use DTest;
use DImportInto;

# 01 {{{1
# Vars to hold the debug output from os(), since os() processing happens
# at compile time, and the stack trace doesn't point us here.
our ($t1, $t2);

my $hrOpts = {};

os 't21::t1' $hrOpts my $a1;
is($t1->{code}, 'my $a1;', 'os() grabs a statement');

os 't21::t2' $hrOpts {my $a2; my $b2;};
is($t2->{code}, '{my $a2; my $b2;}', 'os() grabs a block');

BEGIN {
    eval { local $SIG{'__DIE__'}; os $hrOpts my $a3; };
    ok(!$@, 'os() with statement, without debug, succeeded');
}

BEGIN {
    eval { local $SIG{'__DIE__'}; os $hrOpts {my $a4; my $b4;}; };
    ok(!$@, 'os() with block, without debug, succeeded');
}

# }}}1

is($TEST_NUMBER_OS, 5, 'TEST_NUMBER_OS increments');

# 02 {{{1
$hrOpts->{skip} = { 6=>true, 8=>true };

os $hrOpts ok(1, 'Test 5');     # This one should run

is($TEST_NUMBER_OS, 6, '$TEST_NUMBER_OS increments to 6');

os $hrOpts ok(0, 'Test 6 - should be skipped');

is($TEST_NUMBER_OS, 7, '$TEST_NUMBER_OS increments to 7');

os $hrOpts ok(1, 'Test 7');     # This one should run

is($TEST_NUMBER_OS, 8, '$TEST_NUMBER_OS increments to 8');

os $hrOpts ok(0, 'Test 8 - should be skipped');

is($TEST_NUMBER_OS, 9, '$TEST_NUMBER_OS increments to 9');

# }}}1

# 03 {{{1

$hrOpts->{skip}->{10} = true;
$hrOpts->{skip}->{14} = true;

os $hrOpts ok(1, 'Test 9');     # This one should run

$hrOpts->{n} = 2;
os $hrOpts {
    ok(0, 'Test 10 - should be skipped');
    ok(0, 'Test 11 - should be skipped');
}

is($TEST_NUMBER_OS, 12, '$TEST_NUMBER_OS increments to 12');

os $hrOpts {
    ok(1, 'Test 12');
    ok(1, 'Test 13');
}

is($TEST_NUMBER_OS, 14, '$TEST_NUMBER_OS increments to 14');

$hrOpts->{n} = 3;
os $hrOpts {
    ok(0, 'Test 14 - should be skipped');
    ok(0, 'Test 15 - should be skipped');
    ok(0, 'Test 16 - should be skipped');
}

is($TEST_NUMBER_OS, 17, '$TEST_NUMBER_OS increments to 17');

$hrOpts->{n} = 1;
# }}}1

# 04 {{{1

skip_these $hrOpts, 18, 19;

os $hrOpts ok(1, 'Test 17');     # This one should run
os $hrOpts ok(0, 'Test 18 - should be skipped');
os $hrOpts ok(0, 'Test 19 - should be skipped');
os $hrOpts ok(1, 'Test 20');     # This one should run

is($TEST_NUMBER_OS, 21, '$TEST_NUMBER_OS increments to 21');

is_deeply($hrOpts, {skip => {6=>true, 8=>true, 10=>true, 14=>true, 18=>true,
                                19=>true}, n=>1},
    'Options structure is what we set');
is_deeply($TEST_ONLYSOME, {n=>1, skip=>{}, verbose=>0}, '$TEST_ONLYSOME has only the default content');

# }}}1

# 05 {{{1

os $hrOpts ok(1, 'Test 21');     # This one should run
skip_next $hrOpts;
os $hrOpts ok(0, 'Test 22 - should be skipped');
is($TEST_NUMBER_OS, 23, '$TEST_NUMBER_OS increments to 23');

os $hrOpts ok(1, 'Test 23');     # This one should run

is($hrOpts->{skip}->{22}, true, 'skip->22 is set');
is_deeply($TEST_ONLYSOME, {n=>1, skip=>{}, verbose=>0}, '$TEST_ONLYSOME has only the default content');

# }}}1

done_testing();
# vi: set fdm=marker:
