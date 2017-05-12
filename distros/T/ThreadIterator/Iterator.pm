package Thread::Iterator;
use Thread qw(async);
use Thread::Semaphore;
use Thread::Queue;
use strict;
use vars qw($VERSION @ISA @EXPORT_OK);
use Exporter;
$VERSION = 0.1;
@ISA = 'Exporter';
@EXPORT_OK = 'coroutine';

sub _iter {
    my ($code, $obj) = @_;
    &$code($obj);
    $obj->[2] = 0;
    $obj->[0]->enqueue(undef);
}

sub provide {
    my ($obj, $val) = @_;
    my ($q, $sem) = @$obj;
    $sem->down;
    $q->enqueue($val);
    $sem->down;
}

sub alive {
    my $obj = shift;
    return $obj->[2];
}

sub iterate {
    my $obj = shift;
    my ($q, $sem, $alive) = @$obj;
    my $val;
    if ($alive) {
	$sem->up;
	$val = $q->dequeue;
	$sem->up;
    }
    return $val;
}    

sub new {
    my ($class, $code) = @_;
    my $sem = Thread::Semaphore->new(0);
    my $q = Thread::Queue->new;
    my $obj = bless [$q, $sem, 1], $class;
    Thread->new(\&_iter, $code, $obj);
    return $obj;
}

sub coroutine (&) {
    return __PACKAGE__->new($_[0]);
}

1;
