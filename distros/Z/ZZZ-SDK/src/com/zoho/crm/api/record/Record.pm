require 'src/com/zoho/crm/api/tags/Tag.pm';
require 'src/com/zoho/crm/api/users/User.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package record::Record;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		key_values => undef,
		key_modified => undef,
	};
	bless $self,$class;
	return $self;
}
sub get_id
{
	my ($self) = shift;
	return $self->get_key_value("id"); 
}

sub set_id
{
	my ($self,$id) = @_;
	$self->add_key_value("id", $id); 
}

sub get_created_by
{
	my ($self) = shift;
	return $self->get_key_value("Created_By"); 
}

sub set_created_by
{
	my ($self,$created_by) = @_;
	if(!(($created_by)->isa("users::User")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: created_by EXPECTED TYPE: users::User", undef, undef); 
	}
	$self->add_key_value("Created_By", $created_by); 
}

sub get_created_time
{
	my ($self) = shift;
	return $self->get_key_value("Created_Time"); 
}

sub set_created_time
{
	my ($self,$created_time) = @_;
	if(!(($created_time)->isa("DateTime")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: created_time EXPECTED TYPE: DateTime", undef, undef); 
	}
	$self->add_key_value("Created_Time", $created_time); 
}

sub get_modified_by
{
	my ($self) = shift;
	return $self->get_key_value("Modified_By"); 
}

sub set_modified_by
{
	my ($self,$modified_by) = @_;
	if(!(($modified_by)->isa("users::User")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: modified_by EXPECTED TYPE: users::User", undef, undef); 
	}
	$self->add_key_value("Modified_By", $modified_by); 
}

sub get_modified_time
{
	my ($self) = shift;
	return $self->get_key_value("Modified_Time"); 
}

sub set_modified_time
{
	my ($self,$modified_time) = @_;
	if(!(($modified_time)->isa("DateTime")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: modified_time EXPECTED TYPE: DateTime", undef, undef); 
	}
	$self->add_key_value("Modified_Time", $modified_time); 
}

sub get_tag
{
	my ($self) = shift;
	return $self->get_key_value("Tag"); 
}

sub set_tag
{
	my ($self,$tag) = @_;
	if(!(ref($tag) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: tag EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->add_key_value("Tag", $tag); 
}

sub add_field_value
{
	my ($self,$field,$value) = @_;
	if(!(($field)->isa("record::Field")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: field EXPECTED TYPE: record::Field", undef, undef); 
	}
	$self->add_key_value($field->get_api_name(), $value); 
}

sub add_key_value
{
	my ($self,$api_name,$value) = @_;
	$self->{key_values}{$api_name} = $value; 
	$self->{key_modified}{$api_name} = 1; 
}

sub get_key_value
{
	my ($self,$api_name) = @_;
	if((exists($self->{key_values}{$api_name})))
	{
		return $self->{key_values}{$api_name}; 
	}
	return undef; 
}

sub get_key_values
{
	my ($self) = shift;
	return $self->{key_values}; 
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