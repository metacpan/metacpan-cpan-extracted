package Whelk::OpenAPI;
$Whelk::OpenAPI::VERSION = '0.02';
use Kelp::Base;
use List::Util qw(uniq);

attr info => sub { {} };
attr extra => sub { {} };
attr tags => sub { [] };
attr paths => sub { {} };
attr schemas => sub { {} };
attr servers => sub { [] };

sub default_res_desc
{
	my ($self, $code) = @_;

	state $tries = [
		['204' => 'Success (no content).'],
		['2..' => 'Success.'],
		['4..' => 'Failure, invalid request data.'],
		['5..' => 'Failure, server error.'],
	];

	foreach my $try (@$tries) {
		return $try->[1]
			if $code =~ m{^$try->[0]$};
	}

	return 'Response.';
}

sub _build_path
{
	my ($self, $endpoint) = @_;
	my %requests;
	my %responses;
	my @parameters;

	# bulid responses
	foreach my $code (keys %{$endpoint->response_schemas}) {
		my $schema = $endpoint->response_schemas->{$code};
		my $success = int($code / 100) == 2;

		if ($success && $schema->empty) {

			# special case for no content response
			$responses{204} = {
				description => $schema->description // $self->default_res_desc(204),
			};
		}
		else {
			$responses{$code} = {
				description => $schema->description // $self->default_res_desc($code),
				content => {
					$endpoint->formatter->full_response_format => {
						schema => $schema->openapi_schema($self),
					},
				},
			};
		}
	}

	# build requests
	if (my $schema = $endpoint->request_schema) {
		foreach my $format (values %{$endpoint->formatter->supported_formats}) {
			$requests{content}{$format}{schema} = $schema->openapi_schema($self);
		}
	}

	# build parameters
	foreach my $type (qw(path query header cookie)) {
		my $method = "${type}_schema";
		my $schema = $endpoint->parameters->$method;
		next if !$schema;

		push @parameters, @{$schema->openapi_schema($self, parameters => $type)};
	}

	return {
		($endpoint->id ? (operationId => $endpoint->id) : ()),
		($endpoint->summary ? (summary => $endpoint->summary) : ()),
		($endpoint->description ? (description => $endpoint->description) : ()),
		tags => [$endpoint->resource->name],
		responses => \%responses,
		(@parameters ? (parameters => \@parameters) : ()),
		(%requests ? (requestBody => \%requests) : ()),
	};
}

sub parse
{
	my ($self, %data) = @_;

	$self->info($data{info} // {});
	$self->extra($data{extra} // {});

	$self->servers(
		[
			{
				description => 'API for ' . $data{app}->name,
				url => $data{app}->config('app_url'),
			},
		]
	);

	my %paths;
	my @tags;
	foreach my $endpoint (@{$data{endpoints} // []}) {
		$paths{$endpoint->path}{lc $endpoint->route->method} = $self->_build_path($endpoint);

		push @tags, $endpoint->resource;
	}

	$self->paths(\%paths);

	@tags = map {
		{
			name => $_->name,
			($_->config->{description} ? (description => $_->config->{description}) : ()),
		}
	} uniq @tags;
	$self->tags(\@tags);

	my %schemas = map {
		$_->name => $_->openapi_schema($self, full => 1)
	} @{$data{schemas} // []};

	$self->schemas(\%schemas);
}

sub location_for_schema
{
	my ($self, $name) = @_;

	return "#/components/schemas/$name";
}

sub generate
{
	my ($self) = @_;

	my %generated = (

		# extra at the start, to make sure it's not overshadowing keys
		%{$self->extra},

		openapi => '3.0.3',
		info => $self->info,
		servers => $self->servers,
		tags => $self->tags,
		paths => $self->paths,
		components => {
			schemas => $self->schemas,
		},
	);

	return \%generated;
}

1;

