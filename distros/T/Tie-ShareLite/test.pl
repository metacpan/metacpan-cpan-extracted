# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 12 };
use Tie::ShareLite;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

use vars qw($KEY $ipc %shared);

$KEY = 4923;

# test tie
$ipc = tie %shared, 'Tie::ShareLite', -key     => $KEY,
                                      -mode    => 0600,
                                      -create  => 'yes',
                                      -destroy => 'yes';
ok(defined $ipc);

# store a value
$shared{'testkey1'} = 'testval1';
ok(1);

# fetch that value
ok($shared{'testkey1'}, 'testval1');

# test locking
$ipc->lock( LOCK_EX );
ok(1);

$shared{'testkey2'} = 'testval2';
ok(1);

ok($shared{'testkey1'}, 'testval1');
ok($shared{'testkey2'}, 'testval2');

$ipc->unlock();
ok(1);

# test exists
ok(exists($shared{'testkey2'}));

# test clear
$shared{'testkey1'} = undef;
ok($shared{'testkey1'}, undef);

# test delete
delete($shared{'testkey1'});
ok(!exists($shared{'testkey1'}));
