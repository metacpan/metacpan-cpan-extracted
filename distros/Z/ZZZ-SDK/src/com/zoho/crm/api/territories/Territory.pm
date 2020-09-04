require 'src/com/zoho/crm/api/customviews/Criteria.pm';
require 'src/com/zoho/crm/api/users/User.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package territories::Territory;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		created_time => undef,
		modified_time => undef,
		manager => undef,
		parent_id => undef,
		criteria => undef,
		name => undef,
		modified_by => undef,
		description => undef,
		id => undef,
		created_by => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_created_time
{
	my ($self) = shift;
	return $self->{created_time}; 
}

sub set_created_time
{
	my ($self,$created_time) = @_;
	if(!(($created_time)->isa("DateTime")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: created_time EXPECTED TYPE: DateTime", undef, undef); 
	}
	$self->{created_time} = $created_time; 
	$self->{key_modified}{"created_time"} = 1; 
}

sub get_modified_time
{
	my ($self) = shift;
	return $self->{modified_time}; 
}

sub set_modified_time
{
	my ($self,$modified_time) = @_;
	if(!(($modified_time)->isa("DateTime")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: modified_time EXPECTED TYPE: DateTime", undef, undef); 
	}
	$self->{modified_time} = $modified_time; 
	$self->{key_modified}{"modified_time"} = 1; 
}

sub get_manager
{
	my ($self) = shift;
	return $self->{manager}; 
}

sub set_manager
{
	my ($self,$manager) = @_;
	if(!(($manager)->isa("users::User")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: manager EXPECTED TYPE: users::User", undef, undef); 
	}
	$self->{manager} = $manager; 
	$self->{key_modified}{"manager"} = 1; 
}

sub get_parent_id
{
	my ($self) = shift;
	return $self->{parent_id}; 
}

sub set_parent_id
{
	my ($self,$parent_id) = @_;
	$self->{parent_id} = $parent_id; 
	$self->{key_modified}{"parent_id"} = 1; 
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

sub get_modified_by
{
	my ($self) = shift;
	return $self->{modified_by}; 
}

sub set_modified_by
{
	my ($self,$modified_by) = @_;
	if(!(($modified_by)->isa("users::User")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: modified_by EXPECTED TYPE: users::User", undef, undef); 
	}
	$self->{modified_by} = $modified_by; 
	$self->{key_modified}{"modified_by"} = 1; 
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

sub get_created_by
{
	my ($self) = shift;
	return $self->{created_by}; 
}

sub set_created_by
{
	my ($self,$created_by) = @_;
	if(!(($created_by)->isa("users::User")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: created_by EXPECTED TYPE: users::User", undef, undef); 
	}
	$self->{created_by} = $created_by; 
	$self->{key_modified}{"created_by"} = 1; 
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