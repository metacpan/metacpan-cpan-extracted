package Whelk::Resource::Typo::Endpoint;

use Kelp::Base 'Whelk::Resource';
use Whelk::Exception;

sub api
{
	my ($self) = @_;

	$self->add_endpoint(
		'/' => sub { },
		ersponse => {
			type => 'array',
		}
	);
}

1;

