require 'src/com/zoho/crm/api/util/Choice.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package sharerecords::APIException;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		status => undef,
		code => undef,
		message => undef,
		details => undef,
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
	if(!(($status)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: status EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{status} = $status; 
	$self->{key_modified}{"status"} = 1; 
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