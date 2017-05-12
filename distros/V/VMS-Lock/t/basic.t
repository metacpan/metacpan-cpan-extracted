#! perl -w

print "1..15\n";

$test = 1;

use VMS::Lock qw(:lockmodes :accmodes);
print 'ok ', $test++, "\n";

$lock = new VMS::Lock (RESOURCE_NAME => 'TESTLOCK');
print !defined $lock ? 'not ' : '', 'ok ', $test++, "\n";

print $lock->lock_id == 0 ? 'not ' : '', 'ok ', $test++, "\n";
print $lock->lock_mode != 0 ? 'not ' : '', 'ok ', $test++, "\n";
print $lock->resource_name ne 'TESTLOCK' ? 'not ' : '', 'ok ', $test++, "\n";

#
# test conversion to lock modes
#   (no access_mode tests for now)
#

$status = $lock->convert (LOCK_MODE => VLOCK_CRMODE);
print $status != 1 ? 'not ' : '', 'ok ', $test++, "\n";
print $lock->lock_mode != 1 ? 'not ' : '', 'ok ', $test++, "\n";

$status = $lock->convert (LOCK_MODE => VLOCK_CWMODE);
print $status != 1 ? 'not ' : '', 'ok ', $test++, "\n";
print $lock->lock_mode != 2 ? 'not ' : '', 'ok ', $test++, "\n";

$status = $lock->convert (LOCK_MODE => VLOCK_PRMODE);
print $status != 1 ? 'not ' : '', 'ok ', $test++, "\n";
print $lock->lock_mode != 3 ? 'not ' : '', 'ok ', $test++, "\n";

$status = $lock->convert (LOCK_MODE => VLOCK_PWMODE);
print $status != 1 ? 'not ' : '', 'ok ', $test++, "\n";
print $lock->lock_mode != 4 ? 'not ' : '', 'ok ', $test++, "\n";

$status = $lock->convert (LOCK_MODE => VLOCK_EXMODE);
print $status != 1 ? 'not ' : '', 'ok ', $test++, "\n";
print $lock->lock_mode != 5 ? 'not ' : '', 'ok ', $test++, "\n";

undef $lock;
