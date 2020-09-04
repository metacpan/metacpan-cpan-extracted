require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package fields::AssociationDetails;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		lookup_field => undef,
		related_field => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_lookup_field
{
	my ($self) = shift;
	return $self->{lookup_field}; 
}

sub set_lookup_field
{
	my ($self,$lookup_field) = @_;
	if(!(($lookup_field)->isa("fields::LookupField")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: lookup_field EXPECTED TYPE: fields::LookupField", undef, undef); 
	}
	$self->{lookup_field} = $lookup_field; 
	$self->{key_modified}{"lookup_field"} = 1; 
}

sub get_related_field
{
	my ($self) = shift;
	return $self->{related_field}; 
}

sub set_related_field
{
	my ($self,$related_field) = @_;
	if(!(($related_field)->isa("fields::LookupField")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: related_field EXPECTED TYPE: fields::LookupField", undef, undef); 
	}
	$self->{related_field} = $related_field; 
	$self->{key_modified}{"related_field"} = 1; 
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