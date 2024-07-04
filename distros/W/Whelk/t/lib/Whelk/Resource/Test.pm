package Whelk::Resource::Test;

use Kelp::Base 'Whelk::Resource';
use Whelk::Exception;

sub api
{
	my ($self) = @_;

	$self->add_endpoint(
		[GET => '/'] => {
			to => 'home',
		},

		response => {
			type => 'string',
		},
	);

	$self->add_endpoint(
		'/t1' => {
			to => 'Test::test_action',
		},

		response => {
			type => 'object',
			properties => {
				id => {
					type => 'integer',
				},
				name => {
					type => 'string',
				},
			},
		},
	);

	$self->add_endpoint(
		[GET => '/nocontent'] => sub {
			return undef;
		},

		response => {
			type => 'empty',
		},
	);

	$self->add_endpoint(
		[POST => '/err'] => {
			to => 'test#error_action',
		},
	);

	$self->add_endpoint(
		[POST => '/custom_err'] => sub {
			my ($self) = @_;

			$self->res->code(400);
			return 'Something went very wrong';
		},
	);
}

sub home
{
	return 'hello, world!';
}

sub test_action
{
	return {
		id => 1337,
		name => 'elite',
	};
}

sub error_action
{
	Whelk::Exception->throw(418, body => 'no can do');
}

1;

