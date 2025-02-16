package WebService::Chroma::DB;

use Moo;

use MooX::ValidateSubs;
use WebService::Chroma::Collection;
use Types::Standard qw/Str Int ArrayRef HashRef ScalarRef/;

validate_subs (
	create_collection => {
		params => {
			name => [Str],
  			configuration => [HashRef, 1],
  			metadata => [HashRef, 1],
  			get_or_create => [ScalarRef, 1]
		}
	},
	get_collections => {
		params => {
			limit => [Int, 1],
			offset => [Int, 1]
		}
	},
	get_collection => {
		params => {
			name => [Str],
		}
	},
	delete_collection => {
		params => {
			name => [Str],
		}
	},
	count_collections => {
		params => { }
	}
);

has ua => (
	is => 'ro',
	required => 1,
);

has tenant => (
	is => 'ro',
	required => 1,
);

has name => (
	is => 'ro',
	required => 1,
);


sub create_collection {
	my ($self, %data) = @_;

	my $collection = $self->ua->post(
		url => sprintf('/api/v2/tenants/%s/databases/%s/collections', $self->tenant, $self->name),
		data => \%data
	);

	return WebService::Chroma::Collection->new(
		ua => $self->ua,
		tenant => $self->tenant,
		db => $self->name,
		%{$collection}
	);
}

sub get_collections {
	my ($self, %data) = @_;
	my $collections = $self->ua->get(
		url => sprintf('/api/v2/tenants/%s/databases/%s/collections', $self->tenant, $self->name),
		data => \%data
	);
	return [map {
		WebService::Chroma::Collection->new(
			ua => $self->ua,
			tenant => $self->tenant,
			db => $self->name,
			%{$_}
		);
	} @{$collections}]
}

sub get_collection {
	my ($self, %data) = @_;

	my $collection = $self->ua->get(
		url => sprintf('/api/v2/tenants/%s/databases/%s/collections/%s', $self->tenant, $self->name, $data{name}),
	);
	
	return WebService::Chroma::Collection->new(
		ua => $self->ua,
		tenant => $self->tenant,
		db => $self->name,
		%{$collection}
	);
}


sub delete_collection {
	my ($self, %data) = @_;

	my $collection = $self->ua->delete(
		url => sprintf('/api/v2/tenants/%s/databases/%s/collections/%s', $self->tenant, $self->name, $data{name}),
	);

	return $collection;
}

sub count_collections {
	my ($self, %data) = @_;
	return $self->ua->get(
		url => sprintf('/api/v2/tenants/%s/databases/%s/collections_count', $self->tenant, $self->name),
	);
}



1;

__END__

=head1 NAME

WebService::Chroma::DB - chromadb database

=head1 VERSION

Version 0.07

=cut

=head1 SYNOPSIS

	use WebService::Chroma::DB;

	my $db = WebService::Chroma::DB->new(
		ua => WebService::Chroma::UA->new(...),
		tenant => '...',
		name => '...',
	);

	my $collection = $db->create_collection(
		name => 'test-collection'
	);


=head1 Methods

=cut

=head2 create_collection

Create a new collection. This returns an L<WebService::Chroma::Collection> object.

	$db->create_collection(
		name => 'test-collection',
  		configuration => { ... },
  		metadata => { ... },
  		get_or_create => \1
	);

=head2 count_collections

Count all collections related to the current database.

	$db->count_collections();

=head2 get_collections

Retrieve all collections related to the current database. This returns a list of L<WebService::Chroma::Collection> objects.

	$db->get_collections(
		limit => 10,
		offset => 0
	);

=head2 get_collection

Retrieve an existing collection. This returns a L<WebService::Chroma::Collection> object.

	$db->get_collection(
		name => 'test-collection'
	);

=head2 delete_collection

Delete an existing collection.

	$db->delete_collection(
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


