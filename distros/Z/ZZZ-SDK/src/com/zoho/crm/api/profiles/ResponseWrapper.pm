require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package profiles::ResponseWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		profiles => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_profiles
{
	my ($self) = shift;
	return $self->{profiles}; 
}

sub set_profiles
{
	my ($self,$profiles) = @_;
	if(!(ref($profiles) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: profiles EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{profiles} = $profiles; 
	$self->{key_modified}{"profiles"} = 1; 
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