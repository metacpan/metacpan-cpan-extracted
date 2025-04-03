package Whelk::Wrapper::WithStatus;
$Whelk::Wrapper::WithStatus::VERSION = '1.03';
use Kelp::Base 'Whelk::Wrapper';

use Whelk::Schema;

sub wrap_server_error
{
	my ($self, $data) = @_;

	return {
		success => 0,
		error => $data,
	};
}

sub wrap_success
{
	my ($self, $data) = @_;

	return {
		success => 1,
		data => $data,
	};
}

sub build_response_schemas
{
	my ($self, $endpoint) = @_;
	my $schema = $endpoint->response;
	my $schemas = $endpoint->response_schemas;

	if ($schema->empty) {
		$schemas->{$endpoint->response_code} = $schema;
	}
	elsif ($schema) {
		$schemas->{$endpoint->response_code} = Whelk::Schema->build(
			{
				type => 'object',
				properties => {
					success => {
						type => 'boolean',
						default => !!1,
					},
					data => [$schema, required => !!1],
				},
			}
		);
	}

	$schemas->{'5XX'} = $schemas->{'4XX'} = Whelk::Schema->get_or_build(
		api_error_with_status => {
			type => 'object',
			properties => {
				success => {
					type => 'boolean',
					default => !!0,
				},
				error => {
					type => 'string',
				},
			},
		}
	);
}

1;

