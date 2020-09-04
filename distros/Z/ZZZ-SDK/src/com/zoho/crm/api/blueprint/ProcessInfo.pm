require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package blueprint::ProcessInfo;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		field_id => undef,
		is_continuous => undef,
		api_name => undef,
		continuous => undef,
		field_label => undef,
		name => undef,
		column_name => undef,
		field_value => undef,
		id => undef,
		field_name => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_field_id
{
	my ($self) = shift;
	return $self->{field_id}; 
}

sub set_field_id
{
	my ($self,$field_id) = @_;
	$self->{field_id} = $field_id; 
	$self->{key_modified}{"field_id"} = 1; 
}

sub get_is_continuous
{
	my ($self) = shift;
	return $self->{is_continuous}; 
}

sub set_is_continuous
{
	my ($self,$is_continuous) = @_;
	$self->{is_continuous} = $is_continuous; 
	$self->{key_modified}{"is_continuous"} = 1; 
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

sub get_continuous
{
	my ($self) = shift;
	return $self->{continuous}; 
}

sub set_continuous
{
	my ($self,$continuous) = @_;
	$self->{continuous} = $continuous; 
	$self->{key_modified}{"continuous"} = 1; 
}

sub get_field_label
{
	my ($self) = shift;
	return $self->{field_label}; 
}

sub set_field_label
{
	my ($self,$field_label) = @_;
	$self->{field_label} = $field_label; 
	$self->{key_modified}{"field_label"} = 1; 
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

sub get_column_name
{
	my ($self) = shift;
	return $self->{column_name}; 
}

sub set_column_name
{
	my ($self,$column_name) = @_;
	$self->{column_name} = $column_name; 
	$self->{key_modified}{"column_name"} = 1; 
}

sub get_field_value
{
	my ($self) = shift;
	return $self->{field_value}; 
}

sub set_field_value
{
	my ($self,$field_value) = @_;
	$self->{field_value} = $field_value; 
	$self->{key_modified}{"field_value"} = 1; 
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

sub get_field_name
{
	my ($self) = shift;
	return $self->{field_name}; 
}

sub set_field_name
{
	my ($self,$field_name) = @_;
	$self->{field_name} = $field_name; 
	$self->{key_modified}{"field_name"} = 1; 
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