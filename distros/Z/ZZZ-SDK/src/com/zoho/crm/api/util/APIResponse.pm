use warnings;

package APIResponse;
use Moose;

has 'status_code' =>(is => "rw");
has 'object' =>(is => "rw");
has 'headers' =>(is => "rw");

sub new
{
	my ($class, $headers, $status_code, $object) = @_;

	my $self =
		{
			headers => $headers,
			status_code => $status_code,
			object => $object,
		};

	bless $self, $class;

	return $self;
}

sub get_headers
{
	my $self = shift;

	return $self->{headers};
}

sub get_status_code
{
	my $self = shift;

	return $self->{status_code};
}

sub get_object
{
	my $self = shift;

	return $self->{object};
}



=head1 NAME

com::zoho::crm::api::util::APIResponse - This class is the common API response object.

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<new>

Creates an APIResponse class instance with the specified parameters.

Param headers : A HashMap representing a APIResponse header.

Param status_code : An integer containing the API response HTTP status code.

Param object : A Object containing the API response POJO class instance.

=item C<get_headers>

This is a getter method to get APIResponse header.

Returns Header of APIResponse object.

=item C<get_status_code>

This is a getter method to get APIResponse status_code.

Returns an Integer indicating status_code for the APIResponse object.

=item C<get_object>

This method to get an API response POJO class instance.

Returns the APIResponse class instance.

=back

=cut

1;
