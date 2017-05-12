use strict;
use warnings;

use Test::More tests => 5;
use Test::SharedFork;
use Test::SharedObject;

my $shared = Test::SharedObject->new(0);
is $shared->get, 0, 'should success to set 0.';
$shared->txn(sub { ++$_[0] });
is $shared->get, 1, 'should get changed value.';
$shared->set(2);
is $shared->get, 2, 'should get set value.';

my $pid = fork;
die $! unless defined $pid; # uncoverable branch
if ($pid == 0) {# child
    $shared->txn(sub { ++$_[0] });
    is $shared->get, 3, 'should get changed value in child process.';
    exit;
}
wait;

is $shared->get, 3,  'should get changed value in parent process.';
