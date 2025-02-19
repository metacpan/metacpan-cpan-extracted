package WebService::Chroma;

our $VERSION = '0.08';

use 5.006;
use strict;
use warnings;

use Moo;
use WebService::Chroma::UA;
use WebService::Chroma::Tenant;

use MooX::ValidateSubs;
use Types::Standard qw/Str ArrayRef HashRef/;

validate_subs (
	create_tenant => {
		params => {
			name => [Str]
		}
	},
	get_tenant => {
		params => {
			name => [Str]
		}
	},
	get_database => {
		params => {
			tenant => [Str],
			name => [Str]
		}
	},
	get_collection => {
		params => {
			tenant => [Str],
			db => [Str],
			name => [Str]
		}
	}
);

has base_url => (
	is => 'ro',
	lazy => 1,
	default => sub { 'http://localhost:8000' }
);

has embeddings_class => (
	is => 'ro',
	lazy => 1,
);

has embeddings_api_key => (
	is => 'ro',
	lazy => 1,
);

has embeddings_base_url => (
	is => 'ro',
	lazy => 1,
);

has embeddings_model => (
	is => 'ro',
	lazy => 1,
);

has ua => (
	is => 'ro',
	builder => sub {
		WebService::Chroma::UA->new(
			base_url => $_[0]->base_url,
			embeddings_class => $_[0]->embeddings_class,
			embeddings_model => $_[0]->embeddings_model,
			embeddings_base_url => $_[0]->embeddings_base_url,
			embeddings_api_key => $_[0]->embeddings_api_key
		);
	}
);

sub version {
	my ($self) = @_;
	return $self->ua->get(url => '/api/v2/version');
}

sub reset {
	my ($self) = @_;
	return $self->ua->post(url => '/api/v2/reset');
}

sub heartbeat {
	my ($self) = @_;
	return $self->ua->get(url => '/api/v2/heartbeat');
}

sub pre_flight_checks {
	my ($self) = @_;
	return $self->ua->get(url => '/api/v2/pre-flight-checks');
}

sub auth_identity {
	my ($self) = @_;
	return $self->ua->get(url => '/api/v2/auth/identity');
}

sub create_tenant {
	my ($self, %data) = @_;

	my $tenant = $self->ua->post(
		url => '/api/v2/tenants',
		data => \%data
	);

	return $self->get_tenant(%data);
}

sub get_tenant {
	my ($self, %data) = @_;

	my $tenant = $self->ua->get(url => '/api/v2/tenants/' . $data{name});
	
	return WebService::Chroma::Tenant->new(
		ua => $self->ua,
		%{$tenant}
	);
}

sub get_database {
	my ($self, %data) = @_;
	return $self->get_tenant(name => $data{tenant})->get_database(name => $data{name});
}

sub get_collection {
	my ($self, %data) = @_;
	return $self->get_tenant(name => $data{tenant})->get_database(name => $data{db})->get_collection(name => $data{name});
}

1;

__END__

=head1 NAME

WebService::Chroma - chromadb client

=head1 VERSION

Version 0.08

=cut

=head1 SYNOPSIS

	use WebService::Chroma;

	my $chroma = WebService::Chroma->new(
		embeddings_class => 'OpenAI', # you will need OPENAI_API_KEY env variable set
	);

	my $version = $chroma->version();

	my $tenant = $chroma->create_tenant(
		name => 'testing-tenant'
	);

	my $db = $tenant->create_database(
		name => 'testing-db'
	);

	my $collection = $db->create_collection(
		name => 'testing'
	);

	...

	my $db = $chroma->get_tenant(
		name => 'testing-tenant'
	)->get_database(
		name => 'testing-db'
	);

	my $collection = $db->get_collection(
		name => 'testing'
	);

	$collection->add(
		documents => [
			'a blue scarf, a red hat, a woolly jumper, black gloves',
			'a pink scarf, a blue hat, a woolly jumper, green gloves'
		],
		ids => [
			"1",
			"2"
		]
	);

	$collection->query(
		query_texts => [
			'a pink scarf, a blue hat, green gloves'
		],
		n_results => 1
	);

=head1 Description

Chroma is the AI-native open-source vector database. Chroma makes it easy to build LLM apps by making knowledge, facts, and skills pluggable for LLMs.

L<https://docs.trychroma.com/getting-started>
L<https://docs.trychroma.com/deployment/client-server-mode>

	chroma run --path /db_path

L<http://localhost:8000/docs>

=cut

=head1 Methods

=cut

=head2 new

Instantiate a new L<WebService::Chroma> object.

	my $chroma = WebService::Chroma->new(
		base_url => 'http://localhost:8000',
		embeddings_class => 'Ollama',
		embeddings_model => 'nomic-embed-text',
		embeddings_base_url => 'http://localhost:11434'
	);

...

	my $chroma = WebService::Chroma->new(
		embeddings_class => 'Jina',
		embeddings_api_key => '...',
	);

=head3 base_url

The base url for chroma default is http://localhost:8000.

=head3 embeddings_class

The embeddings class used to generate embeddings current built in options are Jina, Ollama or OpenAI.

=head3 embeddings_model

The embeddings class model the default for Jina is jina-clip-v2 the default for Ollama is nomic-embed-text and the default for OpenAI is text-embedding-3-large.

=head3 embeddings_api_key

The embeddings class api_key.

=head3 embeddings_base_url

The embeddings class base url, this defaults to http://localhost:11434 for Ollama.

=head2 version

Retrieve chroma version.

	$chroma->version();

=head2 reset

Reset chroma instance.

	$chroma->reset();

=head2 heartbeat

Heartbeat of chroma.

	$chroma->heartbeat();

=head2 pre_flight_checks

Check status of pre flight checks.

	$chroma->pre_flight_checks();

=head2 auth_identity

Get user identity.

	$chroma->auth_identity();

=head2 create_tenant

Create a new tenant. This returns a L<WebService::Chroma::Tenant> object.

	$chroma->create_tenant(
		name => 'test-tenant'
	);


=head2 get_tenant

Retrieve an existing tenant. This returns a L<WebService::Chroma::Tenant> object.

	$chroma->get_tenant(
		name => 'test-tenant'
	);

=head2 get_database

Retrieve an existing database. This returns a L<WebService::Chroma::DB> object.

	$chroma->get_database(
		tenant => 'test-tenant',
		name => 'test-database',
	);

=head2 get_collection

Retrieve an existing collection. This return a L<WebService::Chroma::Collection> object.

	$chroma->get_collection(
		tenant => 'test-tenant',
		db => 'test-database',
		name => 'test-collection'
	);
	
=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-chroma at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Chroma>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Chroma

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Chroma>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/WebService-Chroma>

=item * Search CPAN

L<https://metacpan.org/release/WebService-Chroma>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of WebService::Chroma
