require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package fields::MultiSelectLookup;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		display_label => undef,
		linking_module => undef,
		lookup_apiname => undef,
		api_name => undef,
		connectedlookup_apiname => undef,
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

sub get_linking_module
{
	my ($self) = shift;
	return $self->{linking_module}; 
}

sub set_linking_module
{
	my ($self,$linking_module) = @_;
	$self->{linking_module} = $linking_module; 
	$self->{key_modified}{"linking_module"} = 1; 
}

sub get_lookup_apiname
{
	my ($self) = shift;
	return $self->{lookup_apiname}; 
}

sub set_lookup_apiname
{
	my ($self,$lookup_apiname) = @_;
	$self->{lookup_apiname} = $lookup_apiname; 
	$self->{key_modified}{"lookup_apiname"} = 1; 
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

sub get_connectedlookup_apiname
{
	my ($self) = shift;
	return $self->{connectedlookup_apiname}; 
}

sub set_connectedlookup_apiname
{
	my ($self,$connectedlookup_apiname) = @_;
	$self->{connectedlookup_apiname} = $connectedlookup_apiname; 
	$self->{key_modified}{"connectedlookup_apiname"} = 1; 
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