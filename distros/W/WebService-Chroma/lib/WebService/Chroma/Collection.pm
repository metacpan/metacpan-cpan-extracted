package WebService::Chroma::Collection;

use Moo;

has ua => (
	is => 'ro',
	required => 1,
);

has tenant => (
	is => 'ro',
	required => 1,
);

has db => (
	is => 'ro',
	required => 1,
);

has id => (
	is => 'ro',
	required => 1,
);

has name => (
	is => 'ro',
	required => 1,
);

sub add {
	my ($self, %data) = @_; 

	return $self->ua->post(
		url => sprintf('/api/v2/tenants/%s/databases/%s/collections/%s/add', $self->tenant, $self->db, $self->id),
		data => \%data
	);
}

sub upsert {
	my ($self, %data) = @_; 
	
	return $self->ua->post(
		url => sprintf('/api/v2/tenants/%s/databases/%s/collections/%s/upsert', $self->tenant, $self->db, $self->id),
		data => \%data
	);
}

sub update {
	my ($self, %data) = @_; 
	
	return $self->ua->post(
		url => sprintf('/api/v2/tenants/%s/databases/%s/collections/%s/update', $self->tenant, $self->db, $self->id),
		data => \%data
	);
}

sub get {
	my ($self, %data) = @_;

	return $self->ua->post(
		url => sprintf('/api/v2/tenants/%s/databases/%s/collections/%s/get', $self->tenant, $self->db, $self->id),
		data => \%data
	);
}

sub query {
	my ($self, %data) = @_;

	return $self->ua->post(
		url => sprintf('/api/v2/tenants/%s/databases/%s/collections/%s/query', $self->tenant, $self->db, $self->id),
		data => \%data
	);
}

sub delete {
	my ($self, %data) = @_;
	
	return $self->ua->post(
		url => sprintf('/api/v2/tenants/%s/databases/%s/collections/%s/delete', $self->tenant, $self->db, $self->id),
		data => \%data
	);
}

1;

__END__

=head1 NAME

WebService::Chroma::Collection - chromadb collection

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

	use WebService::Chroma::Collection;

	my $collection = WebService::Chroma::Collection->new(
		ua => WebService::Chroma::UA->new(...),
		tenant => '...',
		db => '...',
		id => '...',
		name => '...',
	);

=head1 Methods

=cut

=head2 add

=head2 upsert

=head2 update

=head2 get

=head2 query

=head2 delete

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


