require 'src/com/zoho/crm/api/layouts/Layout.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package fields::Module;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		layout => undef,
		display_label => undef,
		api_name => undef,
		module => undef,
		id => undef,
		module_name => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_layout
{
	my ($self) = shift;
	return $self->{layout}; 
}

sub set_layout
{
	my ($self,$layout) = @_;
	if(!(($layout)->isa("layouts::Layout")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: layout EXPECTED TYPE: layouts::Layout", undef, undef); 
	}
	$self->{layout} = $layout; 
	$self->{key_modified}{"layout"} = 1; 
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

sub get_module_name
{
	my ($self) = shift;
	return $self->{module_name}; 
}

sub set_module_name
{
	my ($self,$module_name) = @_;
	$self->{module_name} = $module_name; 
	$self->{key_modified}{"module_name"} = 1; 
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