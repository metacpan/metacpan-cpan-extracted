require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package org::LicenseDetails;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		paid_expiry => undef,
		users_license_purchased => undef,
		trial_type => undef,
		trial_expiry => undef,
		paid => undef,
		paid_type => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_paid_expiry
{
	my ($self) = shift;
	return $self->{paid_expiry}; 
}

sub set_paid_expiry
{
	my ($self,$paid_expiry) = @_;
	if(!(($paid_expiry)->isa("DateTime")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: paid_expiry EXPECTED TYPE: DateTime", undef, undef); 
	}
	$self->{paid_expiry} = $paid_expiry; 
	$self->{key_modified}{"paid_expiry"} = 1; 
}

sub get_users_license_purchased
{
	my ($self) = shift;
	return $self->{users_license_purchased}; 
}

sub set_users_license_purchased
{
	my ($self,$users_license_purchased) = @_;
	$self->{users_license_purchased} = $users_license_purchased; 
	$self->{key_modified}{"users_license_purchased"} = 1; 
}

sub get_trial_type
{
	my ($self) = shift;
	return $self->{trial_type}; 
}

sub set_trial_type
{
	my ($self,$trial_type) = @_;
	$self->{trial_type} = $trial_type; 
	$self->{key_modified}{"trial_type"} = 1; 
}

sub get_trial_expiry
{
	my ($self) = shift;
	return $self->{trial_expiry}; 
}

sub set_trial_expiry
{
	my ($self,$trial_expiry) = @_;
	$self->{trial_expiry} = $trial_expiry; 
	$self->{key_modified}{"trial_expiry"} = 1; 
}

sub get_paid
{
	my ($self) = shift;
	return $self->{paid}; 
}

sub set_paid
{
	my ($self,$paid) = @_;
	$self->{paid} = $paid; 
	$self->{key_modified}{"paid"} = 1; 
}

sub get_paid_type
{
	my ($self) = shift;
	return $self->{paid_type}; 
}

sub set_paid_type
{
	my ($self,$paid_type) = @_;
	$self->{paid_type} = $paid_type; 
	$self->{key_modified}{"paid_type"} = 1; 
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