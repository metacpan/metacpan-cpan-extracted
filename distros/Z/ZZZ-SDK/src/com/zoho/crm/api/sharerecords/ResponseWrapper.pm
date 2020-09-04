require 'src/com/zoho/crm/api/users/User.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package sharerecords::ResponseWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		share => undef,
		shareable_user => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_share
{
	my ($self) = shift;
	return $self->{share}; 
}

sub set_share
{
	my ($self,$share) = @_;
	if(!(ref($share) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: share EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{share} = $share; 
	$self->{key_modified}{"share"} = 1; 
}

sub get_shareable_user
{
	my ($self) = shift;
	return $self->{shareable_user}; 
}

sub set_shareable_user
{
	my ($self,$shareable_user) = @_;
	if(!(ref($shareable_user) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: shareable_user EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{shareable_user} = $shareable_user; 
	$self->{key_modified}{"shareable_user"} = 1; 
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