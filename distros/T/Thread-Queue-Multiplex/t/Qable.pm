package Qable;
use Thread::Queue::Queueable;

use base qw(Thread::Queue::Queueable);

sub new {
	return bless {}, shift;
}

sub onEnqueue {
	my $obj = shift;
	my $class = ref $obj;
#	print STDERR "$class object enqueued\n";
	return $obj->SUPER::onEnqueue;
}

sub onDequeue {
	my ($class, $obj) = @_;
#	print STDERR "$class object dequeued\n";
	return $class->SUPER::onDequeue($obj);
}

sub onCancel {
	my $obj = shift;
#	print STDERR "Item cancelled.\n";
	1;
}

sub curse {
	my $obj = shift;
	return $obj->SUPER::curse;
}

sub redeem {
	my ($class, $obj) = @_;
	return $class->SUPER::redeem($obj);
}

1;
