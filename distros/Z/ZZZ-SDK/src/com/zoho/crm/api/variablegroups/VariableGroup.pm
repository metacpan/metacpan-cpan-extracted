require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package variablegroups::VariableGroup;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		display_label => undef,
		api_name => undef,
		name => undef,
		description => undef,
		id => undef,
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