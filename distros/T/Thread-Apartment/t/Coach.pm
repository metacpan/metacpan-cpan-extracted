package Coach;

use Thread::Apartment::MuxServer;
use ThirdBase;

use base qw(ThirdBase Thread::Apartment::MuxServer);

use strict;
use warnings;
#
#	use ThirdBase constructor
#
sub new { return ThirdBase::new(@_); }

sub run {
	my $self = shift;

	sleep 1
		while ($self->handle_method_requests());

	return 1;
}

1;
