use strict;
use warnings;

use Test::More tests => 2;
use Test::SharedFork;
use Test::SharedObject;

my $shared = Test::SharedObject->new(0);
is $shared->get, 0, 'should success to set 0.';

for (1..50) {
    my $pid = fork;
    die $! unless defined $pid; # uncoverable branch
    if ($pid == 0) {# child
        sleep 1;
        $shared->txn(sub { ++$_[0] });
        exit;
    }
}

sleep 1;
wait for 1..50;

is $shared->get, 50, 'should get changed value in parent process.';
