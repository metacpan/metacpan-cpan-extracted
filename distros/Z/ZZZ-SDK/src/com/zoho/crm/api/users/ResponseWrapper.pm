require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package users::ResponseWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		users => undef,
		info => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_users
{
	my ($self) = shift;
	return $self->{users}; 
}

sub set_users
{
	my ($self,$users) = @_;
	if(!(ref($users) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: users EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{users} = $users; 
	$self->{key_modified}{"users"} = 1; 
}

sub get_info
{
	my ($self) = shift;
	return $self->{info}; 
}

sub set_info
{
	my ($self,$info) = @_;
	if(!(($info)->isa("users::Info")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: info EXPECTED TYPE: users::Info", undef, undef); 
	}
	$self->{info} = $info; 
	$self->{key_modified}{"info"} = 1; 
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