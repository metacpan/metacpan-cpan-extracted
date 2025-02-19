package WebService::Chroma::Collection;

use Moo;

use MooX::ValidateSubs;
use Types::Standard qw/Str Int ArrayRef HashRef ScalarRef/;

validate_subs (
	add => {
		params => {
			embeddings => [ArrayRef, 1],
			metadatas => [ArrayRef, 1],
			uris => [ArrayRef, 1],
  			documents => [ArrayRef],
  			ids => [ArrayRef],
		}
	},
	upsert => {
		params => {
			embeddings => [ArrayRef, 1],
			metadatas => [ArrayRef, 1],
			uris => [ArrayRef, 1],
  			documents => [ArrayRef],
  			ids => [ArrayRef],
		}
	},
	update => {
		params => {
			embeddings => [ArrayRef, 1],
			metadatas => [ArrayRef, 1],
			uris => [ArrayRef, 1],
  			documents => [ArrayRef],
  			ids => [ArrayRef],
		}
	},
	get => {
		params => {
			ids => [ArrayRef, 1],
			where => [HashRef, 1],
			where_document => [HashRef, 1],
			sort => [Str, 1],
			limit => [Int, 1],
			offset => [Int, 1],
			include => [ArrayRef, 1]
		}
	},
	delete => {
		params => {
			ids => [ArrayRef, 1],
			where => [HashRef, 1],
			where_document => [HashRef, 1],
		}
	},
	query => {
		params => {
			query_texts => [ArrayRef, 1],
			query_embeddings => [ArrayRef, 1],
			n_results => [Int, 1],
			include => [ArrayRef, 1],
			where => [HashRef, 1],
			where_document => [HashRef, 1],
		}
	},
	count => {
		params => {}
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


sub _automagic_embeddings {
	my ($self, $data) = @_;

	if (! $data->{embeddings} && $self->ua->embeddings) {
		$data->{embeddings} = [];
		for (@{ $data->{documents} }) {
			push @{$data->{embeddings}}, $self->ua->embeddings->get($_);
		}
	}
}

sub add {
	my ($self, %data) = @_; 
	
	$self->_automagic_embeddings(\%data);

	return $self->ua->post(
		url => sprintf('/api/v2/tenants/%s/databases/%s/collections/%s/add', $self->tenant, $self->db, $self->id),
		data => \%data
	);
}

sub upsert {
	my ($self, %data) = @_; 

	$self->_automagic_embeddings(\%data);
	
	return $self->ua->post(
		url => sprintf('/api/v2/tenants/%s/databases/%s/collections/%s/upsert', $self->tenant, $self->db, $self->id),
		data => \%data
	);
}

sub update {
	my ($self, %data) = @_; 
	
	$self->_automagic_embeddings(\%data);
	
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

	if ($data{query_texts} && $self->ua->embeddings) {
		$data{query_embeddings} = [ map { $self->ua->embeddings->get($_) } @{ delete $data{query_texts} } ];
	}

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

sub count {
	my ($self, %data) = @_;

	return $self->ua->get(
		url => sprintf('/api/v2/tenants/%s/databases/%s/collections/%s/count', $self->tenant, $self->db, $self->id),
	)
}

1;

__END__

=head1 NAME

WebService::Chroma::Collection - chromadb collection

=head1 VERSION

Version 0.08

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

=head1 Methods

=cut

=head2 add

Add items to the collection.

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

=head2 upsert

Update or insert items into the collection.

	$collection->upsert(
		documents => [
			'a blue scarf, a red hat, a woolly jumper, black gloves',
			'a pink scarf, a blue hat, a woolly jumper, green gloves'
		],
		ids => [
			"1",
			"2"
		]
	);

=head2 update

Update items in the collection.

	$collection->update(
		documents => [
			'a blue scarf, a red hat, a woolly jumper, black gloves',
			'a pink scarf, a blue hat, a woolly jumper, green gloves'
		],
		ids => [
			"1",
			"2"
		]
	);

=head2 get

Retrieve items from the collection.

	$collection->get(
		ids => [
			"1",
			"2"
		]
	);

=head2 query

Retrieve items from the collection by query.

	 $collection->query(
                query_texts => [
                        'a pink scarf, a blue hat, green gloves'
                ],
                n_results => 1
        );

=head2 delete

Delete items from the collection.

	$collection->delete(
		ids => [
			"1",
			"2"
		]
	);

=head2 count

Returns the count for total number of items in the collection.

	$collection->count();

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


