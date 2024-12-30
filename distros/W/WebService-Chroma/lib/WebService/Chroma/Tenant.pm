package WebService::Chroma::Tenant;

use Moo;

use MooX::ValidateSubs;
use WebService::Chroma::DB;
use Types::Standard qw/Str ArrayRef HashRef/;

validate_subs (
	create_database => {
		params => {
			name => [Str]
		}
	},
	get_database => {
		params => {
			name => [Str]
		}
	}
);

has ua => (
	is => 'ro',
	required => 1,
);

has name => (
	is => 'ro',
	required => 1,
);

sub create_database {
	my ($self, %data) = @_;
	
	$self->ua->post(
		url => sprintf("/api/v2/tenants/%s/databases", $self->name),
		data => \%data
	);

	return $self->get_database(%data);
}

sub get_database {
	my ($self, %data) = @_;
	
	my $db = $self->ua->get(
		url => sprintf("/api/v2/tenants/%s/databases/%s", $self->name, $data{name}),
	);

	return WebService::Chroma::DB->new(
		ua => $self->ua,
		tenant => $self->name,
		%{$db}
	);
}

1;

__END__

=head1 NAME

WebService::Chroma::Tenant - chromadb tenant

=head1 VERSION

Version 0.06

=cut

=head1 SYNOPSIS

	use WebService::Chroma::Tenant;

	my $tenant = WebService::Chroma::Tenant->new(
		ua => WebService::Chroma::UA->new(...),
		name => '...',
	);

	my $db = $tenant->create_database(
		name => 'test-database'
	);

=head1 Methods

=cut

=head2 create_database

Create a new database. This returns a L<WebService::Chroma::DB> object.

	$tenant->create_database(
		name => 'test-database'
	);


=head2 get_database

Retrieve an existing database. This returns a L<WebService::Chroma::DB> object.

	$tenant->get_database(
		name => 'test-database'
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


