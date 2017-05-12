use strict;
use warnings;

use Test::More tests => 4;
use Test::SharedFork;
use Test::SharedObject;

my $shared = Test::SharedObject->new({});
is_deeply $shared->get, {}, 'should success to set empty hash-ref.';
$shared->txn(sub {
    my $hash = shift;
    $hash->{a} = 1;
    $hash->{b} = 2;
    $hash->{c} = 3;
    return $hash;
});
is_deeply $shared->get, {
    a => 1,
    b => 2,
    c => 3,
}, 'should get changed value.';

my $pid = fork;
die $! unless defined $pid; # uncoverable branch
if ($pid == 0) {# child
    $shared->txn(sub {
        my $hash = shift;
        $hash->{a}++;
        $hash->{b}++;
        $hash->{c}++;
        return $hash;
    });
    is_deeply $shared->get, {
        a => 2,
        b => 3,
        c => 4,
    }, 'should get changed value in child process.';
    exit;
}
wait;

is_deeply $shared->get, {
    a => 2,
    b => 3,
    c => 4,
},  'should get changed value in parent process.';
