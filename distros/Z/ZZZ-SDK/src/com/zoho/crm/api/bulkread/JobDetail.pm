require 'src/com/zoho/crm/api/users/User.pm';
require 'src/com/zoho/crm/api/util/Choice.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package bulkread::JobDetail;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		id => undef,
		operation => undef,
		state => undef,
		query => undef,
		created_by => undef,
		created_time => undef,
		result => undef,
		file_type => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
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

sub get_state
{
	my ($self) = shift;
	return $self->{state}; 
}

sub set_state
{
	my ($self,$state) = @_;
	if(!(($state)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: state EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{state} = $state; 
	$self->{key_modified}{"state"} = 1; 
}

sub get_query
{
	my ($self) = shift;
	return $self->{query}; 
}

sub set_query
{
	my ($self,$query) = @_;
	if(!(($query)->isa("bulkread::Query")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: query EXPECTED TYPE: bulkread::Query", undef, undef); 
	}
	$self->{query} = $query; 
	$self->{key_modified}{"query"} = 1; 
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

sub get_result
{
	my ($self) = shift;
	return $self->{result}; 
}

sub set_result
{
	my ($self,$result) = @_;
	if(!(($result)->isa("bulkread::Result")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: result EXPECTED TYPE: bulkread::Result", undef, undef); 
	}
	$self->{result} = $result; 
	$self->{key_modified}{"result"} = 1; 
}

sub get_file_type
{
	my ($self) = shift;
	return $self->{file_type}; 
}

sub set_file_type
{
	my ($self,$file_type) = @_;
	$self->{file_type} = $file_type; 
	$self->{key_modified}{"file_type"} = 1; 
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