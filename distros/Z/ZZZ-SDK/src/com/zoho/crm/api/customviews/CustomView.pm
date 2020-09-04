require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package customviews::CustomView;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		id => undef,
		name => undef,
		system_name => undef,
		display_value => undef,
		shared_type => undef,
		category => undef,
		sort_by => undef,
		sort_order => undef,
		favorite => undef,
		offline => undef,
		default => undef,
		system_defined => undef,
		criteria => undef,
		shared_details => undef,
		fields => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
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

sub get_system_name
{
	my ($self) = shift;
	return $self->{system_name}; 
}

sub set_system_name
{
	my ($self,$system_name) = @_;
	$self->{system_name} = $system_name; 
	$self->{key_modified}{"system_name"} = 1; 
}

sub get_display_value
{
	my ($self) = shift;
	return $self->{display_value}; 
}

sub set_display_value
{
	my ($self,$display_value) = @_;
	$self->{display_value} = $display_value; 
	$self->{key_modified}{"display_value"} = 1; 
}

sub get_shared_type
{
	my ($self) = shift;
	return $self->{shared_type}; 
}

sub set_shared_type
{
	my ($self,$shared_type) = @_;
	$self->{shared_type} = $shared_type; 
	$self->{key_modified}{"shared_type"} = 1; 
}

sub get_category
{
	my ($self) = shift;
	return $self->{category}; 
}

sub set_category
{
	my ($self,$category) = @_;
	$self->{category} = $category; 
	$self->{key_modified}{"category"} = 1; 
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

sub get_favorite
{
	my ($self) = shift;
	return $self->{favorite}; 
}

sub set_favorite
{
	my ($self,$favorite) = @_;
	$self->{favorite} = $favorite; 
	$self->{key_modified}{"favorite"} = 1; 
}

sub get_offline
{
	my ($self) = shift;
	return $self->{offline}; 
}

sub set_offline
{
	my ($self,$offline) = @_;
	$self->{offline} = $offline; 
	$self->{key_modified}{"offline"} = 1; 
}

sub get_default
{
	my ($self) = shift;
	return $self->{default}; 
}

sub set_default
{
	my ($self,$default) = @_;
	$self->{default} = $default; 
	$self->{key_modified}{"default"} = 1; 
}

sub get_system_defined
{
	my ($self) = shift;
	return $self->{system_defined}; 
}

sub set_system_defined
{
	my ($self,$system_defined) = @_;
	$self->{system_defined} = $system_defined; 
	$self->{key_modified}{"system_defined"} = 1; 
}

sub get_criteria
{
	my ($self) = shift;
	return $self->{criteria}; 
}

sub set_criteria
{
	my ($self,$criteria) = @_;
	if(!(($criteria)->isa("customviews::Criteria")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: criteria EXPECTED TYPE: customviews::Criteria", undef, undef); 
	}
	$self->{criteria} = $criteria; 
	$self->{key_modified}{"criteria"} = 1; 
}

sub get_shared_details
{
	my ($self) = shift;
	return $self->{shared_details}; 
}

sub set_shared_details
{
	my ($self,$shared_details) = @_;
	if(!(ref($shared_details) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: shared_details EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{shared_details} = $shared_details; 
	$self->{key_modified}{"shared_details"} = 1; 
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