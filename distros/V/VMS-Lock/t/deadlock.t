print "1..11\n";

$test = 1;

use VMS::Lock qw(:lockmodes :accmodes);
print 'ok ', $test++, "\n";

$lock = new VMS::Lock (RESOURCE_NAME => 'TESTLOCK');
print !defined $lock ? 'not ' : '', 'ok ', $test++, "\n";
print $lock->lock_mode != 0 ? 'not ' : '', 'ok ', $test++, "\n";

$status = $lock->convert (LOCK_MODE => VLOCK_EXMODE);
print $status != 1 ? 'not ' : '', 'ok ', $test++, "\n";
print $lock->lock_mode != 5 ? 'not ' : '', 'ok ', $test++, "\n";

$newlock = new VMS::Lock (RESOURCE_NAME => 'TESTLOCK');
print !defined $lock ? 'not ' : '', 'ok ', $test++, "\n";
print $newlock->lock_mode != 0 ? 'not ' : '', 'ok ', $test++, "\n";

$status = $newlock->convert (LOCK_MODE => VLOCK_EXMODE);
#$deadlock = $newlock->deadlock;
#print "status = $status, deadlock = $deadlock\n";
if ($status != 0 or $newlock->deadlock == 0) { print 'not ' }
print 'ok ', $test++, "\n";

$status = $newlock->convert (LOCK_MODE => VLOCK_EXMODE, NOQUEUE => 1);
#$convert = $newlock->convert;
#print "status = $status, convert = $convert\n";
if ($status != 0 or $newlock->noqueue == 0) { print 'not ' }
print 'ok ', $test++, "\n";

#
# delete $lock, then try, should be ok
#

undef $lock;

$status = $newlock->convert (LOCK_MODE => VLOCK_EXMODE);
print $status != 1 ? 'not ' : '', 'ok ', $test++, "\n";
print $newlock->lock_mode != 5 ? 'not ' : '', 'ok ', $test++, "\n";

undef $newlock;

