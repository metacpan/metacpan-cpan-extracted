require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package org::ResponseWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		org => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_org
{
	my ($self) = shift;
	return $self->{org}; 
}

sub set_org
{
	my ($self,$org) = @_;
	if(!(ref($org) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: org EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{org} = $org; 
	$self->{key_modified}{"org"} = 1; 
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