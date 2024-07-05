package Whelk::Wrapper::Buggy;

use Kelp::Base 'Whelk::Wrapper';

# Based on Wrapper::Simple
# the bug is that error schema should be a string rather than object or
# wrap_error should convert a string to an object, but it doesn't. This causes
# builtin errors (which are strings) to create a loop or failing inhales, which
# should be broken at some point to avoid endless loop.

sub wrap_server_error
{
	my ($self, $data) = @_;

	return {error => $data};
}

sub wrap_success
{
	my ($self, $data) = @_;

	return $data;
}

sub build_response_schemas
{
	my ($self, $endpoint) = @_;
	my $schema = $endpoint->response;
	my $schemas = $endpoint->response_schemas;

	$schemas->{200} = $schema;

	$schemas->{500} = $schemas->{400} = Whelk::Schema->get_or_build(
		api_error_buggy => {
			type => 'object',
			properties => {
				error => {
					type => 'object',
				},
			},
		}
	);
}

1;

