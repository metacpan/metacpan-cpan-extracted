require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package blueprint::ValidationError;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		api_name => undef,
		message => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_api_name
{
	my ($self) = shift;
	return $self->{api_name}; 
}

sub set_api_name
{
	my ($self,$api_name) = @_;
	$self->{api_name} = $api_name; 
	$self->{key_modified}{"api_name"} = 1; 
}

sub get_message
{
	my ($self) = shift;
	return $self->{message}; 
}

sub set_message
{
	my ($self,$message) = @_;
	$self->{message} = $message; 
	$self->{key_modified}{"message"} = 1; 
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