require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package profiles::Category;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		display_label => undef,
		permissions_details => undef,
		name => undef,
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

sub get_permissions_details
{
	my ($self) = shift;
	return $self->{permissions_details}; 
}

sub set_permissions_details
{
	my ($self,$permissions_details) = @_;
	if(!(ref($permissions_details) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: permissions_details EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{permissions_details} = $permissions_details; 
	$self->{key_modified}{"permissions_details"} = 1; 
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