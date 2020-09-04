require 'src/com/zoho/crm/api/util/Choice.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package record::Criteria;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		comparator => undef,
		field => undef,
		value => undef,
		group_operator => undef,
		group => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_comparator
{
	my ($self) = shift;
	return $self->{comparator}; 
}

sub set_comparator
{
	my ($self,$comparator) = @_;
	if(!(($comparator)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: comparator EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{comparator} = $comparator; 
	$self->{key_modified}{"comparator"} = 1; 
}

sub get_field
{
	my ($self) = shift;
	return $self->{field}; 
}

sub set_field
{
	my ($self,$field) = @_;
	$self->{field} = $field; 
	$self->{key_modified}{"field"} = 1; 
}

sub get_value
{
	my ($self) = shift;
	return $self->{value}; 
}

sub set_value
{
	my ($self,$value) = @_;
	$self->{value} = $value; 
	$self->{key_modified}{"value"} = 1; 
}

sub get_group_operator
{
	my ($self) = shift;
	return $self->{group_operator}; 
}

sub set_group_operator
{
	my ($self,$group_operator) = @_;
	if(!(($group_operator)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: group_operator EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{group_operator} = $group_operator; 
	$self->{key_modified}{"group_operator"} = 1; 
}

sub get_group
{
	my ($self) = shift;
	return $self->{group}; 
}

sub set_group
{
	my ($self,$group) = @_;
	if(!(ref($group) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: group EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{group} = $group; 
	$self->{key_modified}{"group"} = 1; 
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