require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package record::MassUpdateBodyWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		data => undef,
		cvid => undef,
		ids => undef,
		territory => undef,
		over_write => undef,
		criteria => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_data
{
	my ($self) = shift;
	return $self->{data}; 
}

sub set_data
{
	my ($self,$data) = @_;
	if(!(ref($data) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: data EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{data} = $data; 
	$self->{key_modified}{"data"} = 1; 
}

sub get_cvid
{
	my ($self) = shift;
	return $self->{cvid}; 
}

sub set_cvid
{
	my ($self,$cvid) = @_;
	$self->{cvid} = $cvid; 
	$self->{key_modified}{"cvid"} = 1; 
}

sub get_ids
{
	my ($self) = shift;
	return $self->{ids}; 
}

sub set_ids
{
	my ($self,$ids) = @_;
	if(!(ref($ids) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: ids EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{ids} = $ids; 
	$self->{key_modified}{"ids"} = 1; 
}

sub get_territory
{
	my ($self) = shift;
	return $self->{territory}; 
}

sub set_territory
{
	my ($self,$territory) = @_;
	if(!(($territory)->isa("record::Territory")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: territory EXPECTED TYPE: record::Territory", undef, undef); 
	}
	$self->{territory} = $territory; 
	$self->{key_modified}{"territory"} = 1; 
}

sub get_over_write
{
	my ($self) = shift;
	return $self->{over_write}; 
}

sub set_over_write
{
	my ($self,$over_write) = @_;
	$self->{over_write} = $over_write; 
	$self->{key_modified}{"over_write"} = 1; 
}

sub get_criteria
{
	my ($self) = shift;
	return $self->{criteria}; 
}

sub set_criteria
{
	my ($self,$criteria) = @_;
	if(!(ref($criteria) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: criteria EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{criteria} = $criteria; 
	$self->{key_modified}{"criteria"} = 1; 
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