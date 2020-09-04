require 'src/com/zoho/crm/api/fields/Field.pm';
require 'src/com/zoho/crm/api/record/Record.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package blueprint::Transition;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		next_transitions => undef,
		percent_partial_save => undef,
		data => undef,
		next_field_value => undef,
		name => undef,
		criteria_matched => undef,
		id => undef,
		fields => undef,
		criteria_message => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_next_transitions
{
	my ($self) = shift;
	return $self->{next_transitions}; 
}

sub set_next_transitions
{
	my ($self,$next_transitions) = @_;
	if(!(ref($next_transitions) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: next_transitions EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{next_transitions} = $next_transitions; 
	$self->{key_modified}{"next_transitions"} = 1; 
}

sub get_percent_partial_save
{
	my ($self) = shift;
	return $self->{percent_partial_save}; 
}

sub set_percent_partial_save
{
	my ($self,$percent_partial_save) = @_;
	$self->{percent_partial_save} = $percent_partial_save; 
	$self->{key_modified}{"percent_partial_save"} = 1; 
}

sub get_data
{
	my ($self) = shift;
	return $self->{data}; 
}

sub set_data
{
	my ($self,$data) = @_;
	if(!(($data)->isa("record::Record")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: data EXPECTED TYPE: record::Record", undef, undef); 
	}
	$self->{data} = $data; 
	$self->{key_modified}{"data"} = 1; 
}

sub get_next_field_value
{
	my ($self) = shift;
	return $self->{next_field_value}; 
}

sub set_next_field_value
{
	my ($self,$next_field_value) = @_;
	$self->{next_field_value} = $next_field_value; 
	$self->{key_modified}{"next_field_value"} = 1; 
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

sub get_criteria_matched
{
	my ($self) = shift;
	return $self->{criteria_matched}; 
}

sub set_criteria_matched
{
	my ($self,$criteria_matched) = @_;
	$self->{criteria_matched} = $criteria_matched; 
	$self->{key_modified}{"criteria_matched"} = 1; 
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

sub get_criteria_message
{
	my ($self) = shift;
	return $self->{criteria_message}; 
}

sub set_criteria_message
{
	my ($self,$criteria_message) = @_;
	$self->{criteria_message} = $criteria_message; 
	$self->{key_modified}{"criteria_message"} = 1; 
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