package Whelk::Resource::Test::Deep;

use Kelp::Base 'Whelk::Resource';
use Kelp::Exception;

sub api
{
	my ($self) = @_;

	$self->add_endpoint(
		'/' => {
			to => 'home',
		},

		response => {
			type => 'string',
		},
	);

	$self->add_endpoint(
		[GET => '/err1'] => {
			to => 'test#deep#error_action',
		}
	);

	$self->add_endpoint(
		[GET => '/err2'] => sub {
			die 'this could be a password dump';
		}
	);
}

sub home
{
	return 'hello, world!';
}

sub error_action
{
	Kelp::Exception->throw(400);
}

1;

