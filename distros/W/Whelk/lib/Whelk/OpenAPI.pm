package Whelk::OpenAPI;
$Whelk::OpenAPI::VERSION = '1.04';
use Kelp::Base;
use List::Util qw(uniq);

attr openapi_version => '3.0.3';

attr info => sub { {} };
attr extra => sub { {} };
attr tags => sub { [] };
attr paths => sub { {} };
attr schemas => sub { {} };
attr servers => sub { [] };

sub default_response_description
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

sub build_path
{
	my ($self, $endpoint) = @_;
	my %requests;
	my %responses;
	my @parameters;

	# bulid responses
	foreach my $code (keys %{$endpoint->response_schemas}) {
		my $schema = $endpoint->response_schemas->{$code};
		my $success = $code =~ /2../;

		$responses{$code} = {
			description => $schema->description // $self->default_response_description($code),
		};

		if (!$schema->empty) {
			$responses{$code}{content} = {
				$endpoint->formatter->full_response_format => {
					schema => $schema->openapi_schema($self),
				},
			};
		}
	}

	# build requests
	if (my $schema = $endpoint->request) {
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

sub build_paths
{
	my ($self, $endpoints) = @_;

	my %paths;
	my @tags;
	foreach my $endpoint (@{$endpoints // []}) {
		$paths{$endpoint->path}{lc $endpoint->route->method} = $self->build_path($endpoint);

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
}

sub build_servers
{
	my ($self, $app) = @_;

	$self->servers(
		[
			{
				description => 'API for ' . $app->name,
				url => $app->config('app_url'),
			},
		]
	);
}

sub build_schemas
{
	my ($self, $schemas) = @_;

	my %schemas = map {
		$_->name => $_->openapi_schema($self, full => 1)
	} @{$schemas // []};

	$self->schemas(\%schemas);
}

sub parse
{
	my ($self, %data) = @_;

	$self->info($data{info} // {});
	$self->extra($data{extra} // {});

	$self->build_paths($data{endpoints});
	$self->build_servers($data{app});
	$self->build_schemas($data{schemas});
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

		openapi => $self->openapi_version,
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

__END__

=pod

=head1 NAME

Whelk::OpenAPI - Whelk's default OpenAPI generator class

=head1 SYNOPSIS

	# whelk_config.pl
	###################
	{
		openapi => {
			path => '/openapi',
			class => 'MyOpenAPI',
		}
	}

	# MyOpenAPI.pm
	################
	package MyOpenAPI;

	use Kelp::Base 'Whelk::OpenAPI';

	sub parse {
		my ($self, %data) = @_;

		# do the parsing differently
		...
	}

	1;

=head1 DESCRIPTION

This class generates an OpenAPI document based on the API definition gathered
by Whelk. It requires pretty specific setup and should probably not be
manipulated by hand. It can be subclassed to change how the document looks.

This documentation page describes just the methods which are called from
outside of the class. The rest of methods and all attributes are just
implementation details.

=head1 METHODS

=head2 parse

	$openapi->parse(%data);

It's called at build time, after Whelk is finalized. It gets passed a hash
C<%data> with a couple of keys containing full data Whelk gathered. It should
build most of the parts of the OpenAPI document, so that it will not be
terribly slow to generate the document at runtime.

=head2 location_for_schema

	my $location = $openapi->location_for_schema($schema_name);

This helper should just return a string which will be put into C<'$ref'> keys
of the OpenAPI document to reference named schemas.

=head2 generate

	my $openapi_document_data = $openapi->generate;

This method should take all the data prepared by L</parse> and return a hash
reference with all the data of the OpenAPI document. This data will be then
serialized using formatter declared in C<openapi> configuration.

