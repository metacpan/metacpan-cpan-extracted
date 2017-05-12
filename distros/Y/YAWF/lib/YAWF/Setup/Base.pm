package YAWF::Setup::Base;

use strict;
use warnings;

sub auth {
	my $self = shift;
	
	return 1 if $self->{yawf}->session->{_setup_loggedin};
	
	$self->{yawf}->reply->redir('./');
	
	return 0;
}

1;
