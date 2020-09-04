require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package contactroles::ActionWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		contact_roles => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_contact_roles
{
	my ($self) = shift;
	return $self->{contact_roles}; 
}

sub set_contact_roles
{
	my ($self,$contact_roles) = @_;
	if(!(ref($contact_roles) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: contact_roles EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{contact_roles} = $contact_roles; 
	$self->{key_modified}{"contact_roles"} = 1; 
}

sub is_key_modified
{
	my ($self,$key) = @_;
	if((exists($self->{key_modified}{$key})))
	{
		return $self->{key_modified}{$key}; 
	}
	return undef; 
}

sub set_key_modified
{
	my ($self,$key,$modification) = @_;
	$self->{key_modified}{$key} = $modification; 
}
1;