require 'src/com/zoho/crm/api/util/Choice.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package bulkwrite::APIException;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		code => undef,
		message => undef,
		status => undef,
		details => undef,
		error_message => undef,
		error_code => undef,
		x_error => undef,
		info => undef,
		x_info => undef,
		http_status => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_code
{
	my ($self) = shift;
	return $self->{code}; 
}

sub set_code
{
	my ($self,$code) = @_;
	if(!(($code)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: code EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{code} = $code; 
	$self->{key_modified}{"code"} = 1; 
}

sub get_message
{
	my ($self) = shift;
	return $self->{message}; 
}

sub set_message
{
	my ($self,$message) = @_;
	if(!(($message)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: message EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{message} = $message; 
	$self->{key_modified}{"message"} = 1; 
}

sub get_status
{
	my ($self) = shift;
	return $self->{status}; 
}

sub set_status
{
	my ($self,$status) = @_;
	if(!(($status)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: status EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{status} = $status; 
	$self->{key_modified}{"status"} = 1; 
}

sub get_details
{
	my ($self) = shift;
	return $self->{details}; 
}

sub set_details
{
	my ($self,$details) = @_;
	if(!(ref($details) eq "HASH"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: details EXPECTED TYPE: HASH", undef, undef); 
	}
	$self->{details} = $details; 
	$self->{key_modified}{"details"} = 1; 
}

sub get_error_message
{
	my ($self) = shift;
	return $self->{error_message}; 
}

sub set_error_message
{
	my ($self,$error_message) = @_;
	if(!(($error_message)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: error_message EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{error_message} = $error_message; 
	$self->{key_modified}{"ERROR_MESSAGE"} = 1; 
}

sub get_error_code
{
	my ($self) = shift;
	return $self->{error_code}; 
}

sub set_error_code
{
	my ($self,$error_code) = @_;
	$self->{error_code} = $error_code; 
	$self->{key_modified}{"ERROR_CODE"} = 1; 
}

sub get_x_error
{
	my ($self) = shift;
	return $self->{x_error}; 
}

sub set_x_error
{
	my ($self,$x_error) = @_;
	if(!(($x_error)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: x_error EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{x_error} = $x_error; 
	$self->{key_modified}{"x-error"} = 1; 
}

sub get_info
{
	my ($self) = shift;
	return $self->{info}; 
}

sub set_info
{
	my ($self,$info) = @_;
	if(!(($info)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: info EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{info} = $info; 
	$self->{key_modified}{"info"} = 1; 
}

sub get_x_info
{
	my ($self) = shift;
	return $self->{x_info}; 
}

sub set_x_info
{
	my ($self,$x_info) = @_;
	if(!(($x_info)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: x_info EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{x_info} = $x_info; 
	$self->{key_modified}{"x-info"} = 1; 
}

sub get_http_status
{
	my ($self) = shift;
	return $self->{http_status}; 
}

sub set_http_status
{
	my ($self,$http_status) = @_;
	$self->{http_status} = $http_status; 
	$self->{key_modified}{"http_status"} = 1; 
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