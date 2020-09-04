require 'src/com/zoho/crm/api/users/User.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package bulkwrite::BulkWriteResponse;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		status => undef,
		character_encoding => undef,
		resource => undef,
		id => undef,
		result => undef,
		created_by => undef,
		operation => undef,
		created_time => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_status
{
	my ($self) = shift;
	return $self->{status}; 
}

sub set_status
{
	my ($self,$status) = @_;
	$self->{status} = $status; 
	$self->{key_modified}{"status"} = 1; 
}

sub get_character_encoding
{
	my ($self) = shift;
	return $self->{character_encoding}; 
}

sub set_character_encoding
{
	my ($self,$character_encoding) = @_;
	$self->{character_encoding} = $character_encoding; 
	$self->{key_modified}{"character_encoding"} = 1; 
}

sub get_resource
{
	my ($self) = shift;
	return $self->{resource}; 
}

sub set_resource
{
	my ($self,$resource) = @_;
	if(!(ref($resource) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: resource EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{resource} = $resource; 
	$self->{key_modified}{"resource"} = 1; 
}

sub get_id
{
	my ($self) = shift;
	return $self->{id}; 
}

sub set_id
{
	my ($self,$id) = @_;
	$self->{id} = $id; 
	$self->{key_modified}{"id"} = 1; 
}

sub get_result
{
	my ($self) = shift;
	return $self->{result}; 
}

sub set_result
{
	my ($self,$result) = @_;
	if(!(($result)->isa("bulkwrite::Result")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: result EXPECTED TYPE: bulkwrite::Result", undef, undef); 
	}
	$self->{result} = $result; 
	$self->{key_modified}{"result"} = 1; 
}

sub get_created_by
{
	my ($self) = shift;
	return $self->{created_by}; 
}

sub set_created_by
{
	my ($self,$created_by) = @_;
	if(!(($created_by)->isa("users::User")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: created_by EXPECTED TYPE: users::User", undef, undef); 
	}
	$self->{created_by} = $created_by; 
	$self->{key_modified}{"created_by"} = 1; 
}

sub get_operation
{
	my ($self) = shift;
	return $self->{operation}; 
}

sub set_operation
{
	my ($self,$operation) = @_;
	$self->{operation} = $operation; 
	$self->{key_modified}{"operation"} = 1; 
}

sub get_created_time
{
	my ($self) = shift;
	return $self->{created_time}; 
}

sub set_created_time
{
	my ($self,$created_time) = @_;
	if(!(($created_time)->isa("DateTime")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: created_time EXPECTED TYPE: DateTime", undef, undef); 
	}
	$self->{created_time} = $created_time; 
	$self->{key_modified}{"created_time"} = 1; 
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