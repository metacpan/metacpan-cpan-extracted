require 'src/com/zoho/crm/api/modules/Module.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package sharerecords::SharedThrough;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		module => undef,
		id => undef,
		entity_name => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_module
{
	my ($self) = shift;
	return $self->{module}; 
}

sub set_module
{
	my ($self,$module) = @_;
	if(!(($module)->isa("modules::Module")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: module EXPECTED TYPE: modules::Module", undef, undef); 
	}
	$self->{module} = $module; 
	$self->{key_modified}{"module"} = 1; 
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

sub get_entity_name
{
	my ($self) = shift;
	return $self->{entity_name}; 
}

sub set_entity_name
{
	my ($self,$entity_name) = @_;
	$self->{entity_name} = $entity_name; 
	$self->{key_modified}{"entity_name"} = 1; 
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