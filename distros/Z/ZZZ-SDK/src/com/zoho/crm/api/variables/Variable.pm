require 'src/com/zoho/crm/api/variablegroups/VariableGroup.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package variables::Variable;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		api_name => undef,
		name => undef,
		description => undef,
		id => undef,
		type => undef,
		variable_group => undef,
		value => undef,
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

sub get_name
{
	my ($self) = shift;
	return $self->{name}; 
}

sub set_name
{
	my ($self,$name) = @_;
	$self->{name} = $name; 
	$self->{key_modified}{"name"} = 1; 
}

sub get_description
{
	my ($self) = shift;
	return $self->{description}; 
}

sub set_description
{
	my ($self,$description) = @_;
	$self->{description} = $description; 
	$self->{key_modified}{"description"} = 1; 
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

sub get_type
{
	my ($self) = shift;
	return $self->{type}; 
}

sub set_type
{
	my ($self,$type) = @_;
	$self->{type} = $type; 
	$self->{key_modified}{"type"} = 1; 
}

sub get_variable_group
{
	my ($self) = shift;
	return $self->{variable_group}; 
}

sub set_variable_group
{
	my ($self,$variable_group) = @_;
	if(!(($variable_group)->isa("variablegroups::VariableGroup")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: variable_group EXPECTED TYPE: variablegroups::VariableGroup", undef, undef); 
	}
	$self->{variable_group} = $variable_group; 
	$self->{key_modified}{"variable_group"} = 1; 
}

sub get_value
{
	my ($self) = shift;
	return $self->{value}; 
}

sub set_value
{
	my ($self,$value) = @_;
	$self->{value} = $value; 
	$self->{key_modified}{"value"} = 1; 
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