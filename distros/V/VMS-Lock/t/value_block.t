print "1..17\n";

$test = 1;

use VMS::Lock qw(:lockmodes :accmodes);
print 'ok ', $test++, "\n";

#
# test value_block stuff
#

$lock = new VMS::Lock (RESOURCE_NAME => 'TESTLOCK');
print !defined $lock ? 'not ' : '', 'ok ', $test++, "\n";
print $lock->lock_mode != 0 ? 'not ' : '', 'ok ', $test++, "\n";

$status = $lock->convert (LOCK_MODE => VLOCK_EXMODE);
print $status != 1 ? 'not ' : '', 'ok ', $test++, "\n";
print $lock->lock_mode != 5 ? 'not ' : '', 'ok ', $test++, "\n";

$status = $lock->convert (LOCK_MODE => VLOCK_NLMODE, VALUE_BLOCK => '1234567890123456');
print $status != 1 ? 'not ' : '', 'ok ', $test++, "\n";
print $lock->lock_mode != 0 ? 'not ' : '', 'ok ', $test++, "\n";

$newlock = new VMS::Lock (RESOURCE_NAME => 'TESTLOCK');
print !defined $lock ? 'not ' : '', 'ok ', $test++, "\n";
print $newlock->lock_mode != 0 ? 'not ' : '', 'ok ', $test++, "\n";

$value_block = $newlock->value_block;
print $value_block ne '1234567890123456' ? 'not ' : '', 'ok ', $test++, "\n";

undef $newlock;

$status = $lock->convert (LOCK_MODE => VLOCK_EXMODE);
print $status != 1 ? 'not ' : '', 'ok ', $test++, "\n";
print $lock->lock_mode != 5 ? 'not ' : '', 'ok ', $test++, "\n";

$status = $lock->convert (LOCK_MODE => VLOCK_NLMODE, VALUE_BLOCK => '123456789012345');
print $status != 1 ? 'not ' : '', 'ok ', $test++, "\n";
print $lock->lock_mode != 0 ? 'not ' : '', 'ok ', $test++, "\n";

$newlock = new VMS::Lock (RESOURCE_NAME => 'TESTLOCK');
print !defined $lock ? 'not ' : '', 'ok ', $test++, "\n";
print $newlock->lock_mode != 0 ? 'not ' : '', 'ok ', $test++, "\n";

$value_block = $newlock->value_block;
print length $value_block != 16 ? 'not ' : '', 'ok ', $test++, "\n";

undef $lock;
undef $newlock;
