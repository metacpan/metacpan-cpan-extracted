require 'src/com/zoho/crm/api/users/User.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package sharerecords::ShareRecord;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		share_related_records => undef,
		shared_through => undef,
		shared_time => undef,
		permission => undef,
		shared_by => undef,
		user => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_share_related_records
{
	my ($self) = shift;
	return $self->{share_related_records}; 
}

sub set_share_related_records
{
	my ($self,$share_related_records) = @_;
	$self->{share_related_records} = $share_related_records; 
	$self->{key_modified}{"share_related_records"} = 1; 
}

sub get_shared_through
{
	my ($self) = shift;
	return $self->{shared_through}; 
}

sub set_shared_through
{
	my ($self,$shared_through) = @_;
	if(!(($shared_through)->isa("sharerecords::SharedThrough")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: shared_through EXPECTED TYPE: sharerecords::SharedThrough", undef, undef); 
	}
	$self->{shared_through} = $shared_through; 
	$self->{key_modified}{"shared_through"} = 1; 
}

sub get_shared_time
{
	my ($self) = shift;
	return $self->{shared_time}; 
}

sub set_shared_time
{
	my ($self,$shared_time) = @_;
	if(!(($shared_time)->isa("DateTime")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: shared_time EXPECTED TYPE: DateTime", undef, undef); 
	}
	$self->{shared_time} = $shared_time; 
	$self->{key_modified}{"shared_time"} = 1; 
}

sub get_permission
{
	my ($self) = shift;
	return $self->{permission}; 
}

sub set_permission
{
	my ($self,$permission) = @_;
	$self->{permission} = $permission; 
	$self->{key_modified}{"permission"} = 1; 
}

sub get_shared_by
{
	my ($self) = shift;
	return $self->{shared_by}; 
}

sub set_shared_by
{
	my ($self,$shared_by) = @_;
	if(!(($shared_by)->isa("users::User")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: shared_by EXPECTED TYPE: users::User", undef, undef); 
	}
	$self->{shared_by} = $shared_by; 
	$self->{key_modified}{"shared_by"} = 1; 
}

sub get_user
{
	my ($self) = shift;
	return $self->{user}; 
}

sub set_user
{
	my ($self,$user) = @_;
	if(!(($user)->isa("users::User")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: user EXPECTED TYPE: users::User", undef, undef); 
	}
	$self->{user} = $user; 
	$self->{key_modified}{"user"} = 1; 
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