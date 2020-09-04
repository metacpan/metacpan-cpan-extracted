package UserSignature;
use Moose;
sub new
{
	my ($class, $email) = @_;

	my $self =
	{
		email => $email
	};

	bless $self,$class;

	return $self;
}

sub get_email
{
	my $self=shift;

	return $self->{email};
}

=head1 NAME

com::zoho::api::User - This class represents the CRM user email

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<new>

Creates an User class instance with the specified user email

Param email : A String containing the CRM user email

=item C<get_email>

This is a getter method to get user email

Returns A String representing the CRM user email

=back

=cut

1;
