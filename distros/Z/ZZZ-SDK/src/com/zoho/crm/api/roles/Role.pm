require 'src/com/zoho/crm/api/users/User.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package roles::Role;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		display_label => undef,
		forecast_manager => undef,
		share_with_peers => undef,
		name => undef,
		description => undef,
		id => undef,
		reporting_to => undef,
		admin_user => undef,
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

sub get_forecast_manager
{
	my ($self) = shift;
	return $self->{forecast_manager}; 
}

sub set_forecast_manager
{
	my ($self,$forecast_manager) = @_;
	if(!(($forecast_manager)->isa("users::User")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: forecast_manager EXPECTED TYPE: users::User", undef, undef); 
	}
	$self->{forecast_manager} = $forecast_manager; 
	$self->{key_modified}{"forecast_manager"} = 1; 
}

sub get_share_with_peers
{
	my ($self) = shift;
	return $self->{share_with_peers}; 
}

sub set_share_with_peers
{
	my ($self,$share_with_peers) = @_;
	$self->{share_with_peers} = $share_with_peers; 
	$self->{key_modified}{"share_with_peers"} = 1; 
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

sub get_reporting_to
{
	my ($self) = shift;
	return $self->{reporting_to}; 
}

sub set_reporting_to
{
	my ($self,$reporting_to) = @_;
	if(!(($reporting_to)->isa("users::User")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: reporting_to EXPECTED TYPE: users::User", undef, undef); 
	}
	$self->{reporting_to} = $reporting_to; 
	$self->{key_modified}{"reporting_to"} = 1; 
}

sub get_admin_user
{
	my ($self) = shift;
	return $self->{admin_user}; 
}

sub set_admin_user
{
	my ($self,$admin_user) = @_;
	$self->{admin_user} = $admin_user; 
	$self->{key_modified}{"admin_user"} = 1; 
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