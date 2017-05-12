package Umpire;

use Thread::Apartment::MuxServer;
use Thread::Apartment::Common qw(:ta_method_flags);
use ThirdBase;

use base qw(ThirdBase Thread::Apartment::MuxServer);

use strict;
use warnings;

our $AUTOLOAD;
#
#	use ThirdBase constructor
#
sub new { return ThirdBase::new(@_); }

sub introspect {
	my ($base, $objid) = @_;

	Thread::Apartment::set_autoload(1);
	Thread::Apartment::set_closure_behavior(TA_SIMPLEX);
	Thread::Apartment::set_reentrancy(1);
	return $base->SUPER::introspect($objid);
}

sub run {
	my $self = shift;

	my $result;
	sleep 1
		while $self->handle_method_requests();
	return undef;	# we only leave when STOP'ed
}

sub AUTOLOAD {
	my $self = shift;

	my $method = $AUTOLOAD;
	$method=~s/^.+::(\w+)$/$1/;
	return "Method is $method";
}

sub onDeck {
	my $obj = shift->{_ondeck};
	my $val = $obj->onDeck();
	$val = 'undef' unless $val;
	return 1;
}


1;
