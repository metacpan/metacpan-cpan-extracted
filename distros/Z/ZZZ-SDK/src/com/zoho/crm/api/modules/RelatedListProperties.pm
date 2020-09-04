require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package modules::RelatedListProperties;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		sort_by => undef,
		fields => undef,
		sort_order => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_sort_by
{
	my ($self) = shift;
	return $self->{sort_by}; 
}

sub set_sort_by
{
	my ($self,$sort_by) = @_;
	$self->{sort_by} = $sort_by; 
	$self->{key_modified}{"sort_by"} = 1; 
}

sub get_fields
{
	my ($self) = shift;
	return $self->{fields}; 
}

sub set_fields
{
	my ($self,$fields) = @_;
	if(!(ref($fields) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: fields EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{fields} = $fields; 
	$self->{key_modified}{"fields"} = 1; 
}

sub get_sort_order
{
	my ($self) = shift;
	return $self->{sort_order}; 
}

sub set_sort_order
{
	my ($self,$sort_order) = @_;
	$self->{sort_order} = $sort_order; 
	$self->{key_modified}{"sort_order"} = 1; 
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