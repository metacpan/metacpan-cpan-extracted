require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package relatedlists::RelatedList;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		id => undef,
		sequence_number => undef,
		display_label => undef,
		api_name => undef,
		module => undef,
		name => undef,
		action => undef,
		href => undef,
		type => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
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

sub get_module
{
	my ($self) = shift;
	return $self->{module}; 
}

sub set_module
{
	my ($self,$module) = @_;
	$self->{module} = $module; 
	$self->{key_modified}{"module"} = 1; 
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

sub get_action
{
	my ($self) = shift;
	return $self->{action}; 
}

sub set_action
{
	my ($self,$action) = @_;
	$self->{action} = $action; 
	$self->{key_modified}{"action"} = 1; 
}

sub get_href
{
	my ($self) = shift;
	return $self->{href}; 
}

sub set_href
{
	my ($self,$href) = @_;
	$self->{href} = $href; 
	$self->{key_modified}{"href"} = 1; 
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