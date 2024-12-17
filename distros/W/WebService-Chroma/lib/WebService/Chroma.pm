package WebService::Chroma;

our $VERSION = '0.02';

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
	}

);

has base_url => (
	is => 'ro',
	lazy => 1,
	default => sub { 'http://localhost:8000' }
);

has ua => (
	is => 'ro',
	builder => sub {
		WebService::Chroma::UA->new(
			base_url => $_[0]->base_url
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

1;

__END__

=head1 NAME

WebService::Chroma - chromadb client

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

	use WebService::Chroma;

	my $chroma = WebService::Chroma->new();

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
		embeddings => [
			[1.1, 2.3, 3.2],
			[2.1, 3.3, 4.2],
		],
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
		query_embeddings => [
			[2.1, 3.3, 4.2]
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

=head2 version

=head2 reset

=head2 heartbeat

=head2 pre_flight_checks

=head2 auth_identity

=head2 create_tenant

=head2 get_tenant

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
