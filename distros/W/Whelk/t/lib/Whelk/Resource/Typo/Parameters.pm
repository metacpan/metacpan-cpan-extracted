package Whelk::Resource::Typo::Parameters;

use Kelp::Base 'Whelk::Resource';
use Whelk::Exception;

sub api
{
	my ($self) = @_;

	$self->add_endpoint(
		'/' => sub { },
		parameters => {
			hedaer => {
				test => {
					type => 'string',
				},
			}
		},
		response => {
			type => 'array',
		}
	);
}

1;

