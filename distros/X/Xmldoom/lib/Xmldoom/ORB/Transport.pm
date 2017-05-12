
package Xmldoom::ORB::Transport;

use Xmldoom::ORB::Transport::JSON;
use Xmldoom::ORB::Transport::XML;
use strict;

our $TRANSPORT_MAP = {
	json => 'Xmldoom::ORB::Transport::JSON',
	xml  => 'Xmldoom::ORB::Transport::XML'
};

sub is_valid
{
	return exists $TRANSPORT_MAP->{shift};
}

sub get_transport
{
	my $name = shift;

	if ( exists $TRANSPORT_MAP->{$name} )
	{
		return $TRANSPORT_MAP->{$name}->new();
	}

	return undef;
}

1;

