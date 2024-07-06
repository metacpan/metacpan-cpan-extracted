package Whelk::Wrapper::Simple;
$Whelk::Wrapper::Simple::VERSION = '0.04';
use Kelp::Base 'Whelk::Wrapper';
use Kelp::Exception;

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
		api_error_simple => {
			type => 'object',
			properties => {
				error => {
					type => 'string',
				},
			},
		}
	);
}

1;

