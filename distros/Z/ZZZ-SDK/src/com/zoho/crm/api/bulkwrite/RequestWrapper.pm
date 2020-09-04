require 'src/com/zoho/crm/api/util/Choice.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package bulkwrite::RequestWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		character_encoding => undef,
		operation => undef,
		callback => undef,
		resource => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
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

sub get_operation
{
	my ($self) = shift;
	return $self->{operation}; 
}

sub set_operation
{
	my ($self,$operation) = @_;
	if(!(($operation)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: operation EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{operation} = $operation; 
	$self->{key_modified}{"operation"} = 1; 
}

sub get_callback
{
	my ($self) = shift;
	return $self->{callback}; 
}

sub set_callback
{
	my ($self,$callback) = @_;
	if(!(($callback)->isa("bulkwrite::CallBack")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: callback EXPECTED TYPE: bulkwrite::CallBack", undef, undef); 
	}
	$self->{callback} = $callback; 
	$self->{key_modified}{"callback"} = 1; 
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