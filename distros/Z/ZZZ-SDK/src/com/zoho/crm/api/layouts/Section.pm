require 'src/com/zoho/crm/api/fields/Field.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package layouts::Section;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		display_label => undef,
		sequence_number => undef,
		issubformsection => undef,
		tab_traversal => undef,
		api_name => undef,
		column_count => undef,
		name => undef,
		generated_type => undef,
		fields => undef,
		properties => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_display_label
{
	my ($self) = shift;
	return $self->{display_label}; 
}

sub set_display_label
{
	my ($self,$display_label) = @_;
	$self->{display_label} = $display_label; 
	$self->{key_modified}{"display_label"} = 1; 
}

sub get_sequence_number
{
	my ($self) = shift;
	return $self->{sequence_number}; 
}

sub set_sequence_number
{
	my ($self,$sequence_number) = @_;
	$self->{sequence_number} = $sequence_number; 
	$self->{key_modified}{"sequence_number"} = 1; 
}

sub get_issubformsection
{
	my ($self) = shift;
	return $self->{issubformsection}; 
}

sub set_issubformsection
{
	my ($self,$issubformsection) = @_;
	$self->{issubformsection} = $issubformsection; 
	$self->{key_modified}{"isSubformSection"} = 1; 
}

sub get_tab_traversal
{
	my ($self) = shift;
	return $self->{tab_traversal}; 
}

sub set_tab_traversal
{
	my ($self,$tab_traversal) = @_;
	$self->{tab_traversal} = $tab_traversal; 
	$self->{key_modified}{"tab_traversal"} = 1; 
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

sub get_column_count
{
	my ($self) = shift;
	return $self->{column_count}; 
}

sub set_column_count
{
	my ($self,$column_count) = @_;
	$self->{column_count} = $column_count; 
	$self->{key_modified}{"column_count"} = 1; 
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

sub get_generated_type
{
	my ($self) = shift;
	return $self->{generated_type}; 
}

sub set_generated_type
{
	my ($self,$generated_type) = @_;
	$self->{generated_type} = $generated_type; 
	$self->{key_modified}{"generated_type"} = 1; 
}

sub get_fields
{
	my ($self) = shift;
	return $self->{fields}; 
}

sub set_fields
{
	my ($self,$fields) = @_;
	if(!(ref($fields) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: fields EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{fields} = $fields; 
	$self->{key_modified}{"fields"} = 1; 
}

sub get_properties
{
	my ($self) = shift;
	return $self->{properties}; 
}

sub set_properties
{
	my ($self,$properties) = @_;
	if(!(($properties)->isa("layouts::Properties")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: properties EXPECTED TYPE: layouts::Properties", undef, undef); 
	}
	$self->{properties} = $properties; 
	$self->{key_modified}{"properties"} = 1; 
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