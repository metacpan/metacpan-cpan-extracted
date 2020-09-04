require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package roles::ResponseWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		roles => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_roles
{
	my ($self) = shift;
	return $self->{roles}; 
}

sub set_roles
{
	my ($self,$roles) = @_;
	if(!(ref($roles) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: roles EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{roles} = $roles; 
	$self->{key_modified}{"roles"} = 1; 
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