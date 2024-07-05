package Whelk::Resource::Typo;

use Kelp::Base 'Whelk::Resource';
use Whelk::Exception;

sub api
{
	my ($self) = @_;

	$self->add_endpoint(
		'/' => sub { },
		respnose => {
			type => 'array',
		}
	);
}

1;

