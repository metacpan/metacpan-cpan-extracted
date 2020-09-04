require 'src/com/zoho/crm/api/profiles/Profile.pm';
require 'src/com/zoho/crm/api/users/User.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package layouts::Layout;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		created_time => undef,
		convert_mapping => undef,
		modified_time => undef,
		visible => undef,
		created_for => undef,
		name => undef,
		modified_by => undef,
		profiles => undef,
		id => undef,
		created_by => undef,
		sections => undef,
		status => undef,
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

sub get_convert_mapping
{
	my ($self) = shift;
	return $self->{convert_mapping}; 
}

sub set_convert_mapping
{
	my ($self,$convert_mapping) = @_;
	if(!(ref($convert_mapping) eq "HASH"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: convert_mapping EXPECTED TYPE: HASH", undef, undef); 
	}
	$self->{convert_mapping} = $convert_mapping; 
	$self->{key_modified}{"convert_mapping"} = 1; 
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

sub get_visible
{
	my ($self) = shift;
	return $self->{visible}; 
}

sub set_visible
{
	my ($self,$visible) = @_;
	$self->{visible} = $visible; 
	$self->{key_modified}{"visible"} = 1; 
}

sub get_created_for
{
	my ($self) = shift;
	return $self->{created_for}; 
}

sub set_created_for
{
	my ($self,$created_for) = @_;
	if(!(($created_for)->isa("users::User")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: created_for EXPECTED TYPE: users::User", undef, undef); 
	}
	$self->{created_for} = $created_for; 
	$self->{key_modified}{"created_for"} = 1; 
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

sub get_profiles
{
	my ($self) = shift;
	return $self->{profiles}; 
}

sub set_profiles
{
	my ($self,$profiles) = @_;
	if(!(ref($profiles) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: profiles EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{profiles} = $profiles; 
	$self->{key_modified}{"profiles"} = 1; 
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

sub get_sections
{
	my ($self) = shift;
	return $self->{sections}; 
}

sub set_sections
{
	my ($self,$sections) = @_;
	if(!(ref($sections) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: sections EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{sections} = $sections; 
	$self->{key_modified}{"sections"} = 1; 
}

sub get_status
{
	my ($self) = shift;
	return $self->{status}; 
}

sub set_status
{
	my ($self,$status) = @_;
	$self->{status} = $status; 
	$self->{key_modified}{"status"} = 1; 
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