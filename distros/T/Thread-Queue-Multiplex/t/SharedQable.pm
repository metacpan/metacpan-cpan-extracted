package SharedQable;
use Thread::Queue::Queueable;

use base qw(Thread::Queue::Queueable);

sub new {
	my %obj : shared = ( Value => 1);
	return bless \%obj, shift;
}

sub set_value {
	my $obj = shift;
	$obj->{Value}++;
	return 1;
}

sub get_value { return shift->{Value}; }

sub redeem {
	my ($class, $obj) = @_;
	return bless $obj, $class;
}

1;