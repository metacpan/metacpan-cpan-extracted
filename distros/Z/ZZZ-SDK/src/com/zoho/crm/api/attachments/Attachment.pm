require 'src/com/zoho/crm/api/record/Record.pm';
require 'src/com/zoho/crm/api/users/User.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package attachments::Attachment;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		owner => undef,
		modified_time => undef,
		file_name => undef,
		created_time => undef,
		size => undef,
		parent_id => undef,
		editable => undef,
		file_id => undef,
		type => undef,
		se_module => undef,
		modified_by => undef,
		state => undef,
		id => undef,
		created_by => undef,
		link_url => undef,
		description => undef,
		category => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_owner
{
	my ($self) = shift;
	return $self->{owner}; 
}

sub set_owner
{
	my ($self,$owner) = @_;
	if(!(($owner)->isa("users::User")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: owner EXPECTED TYPE: users::User", undef, undef); 
	}
	$self->{owner} = $owner; 
	$self->{key_modified}{"Owner"} = 1; 
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
	$self->{key_modified}{"Modified_Time"} = 1; 
}

sub get_file_name
{
	my ($self) = shift;
	return $self->{file_name}; 
}

sub set_file_name
{
	my ($self,$file_name) = @_;
	$self->{file_name} = $file_name; 
	$self->{key_modified}{"File_Name"} = 1; 
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
	$self->{key_modified}{"Created_Time"} = 1; 
}

sub get_size
{
	my ($self) = shift;
	return $self->{size}; 
}

sub set_size
{
	my ($self,$size) = @_;
	$self->{size} = $size; 
	$self->{key_modified}{"Size"} = 1; 
}

sub get_parent_id
{
	my ($self) = shift;
	return $self->{parent_id}; 
}

sub set_parent_id
{
	my ($self,$parent_id) = @_;
	if(!(($parent_id)->isa("record::Record")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: parent_id EXPECTED TYPE: record::Record", undef, undef); 
	}
	$self->{parent_id} = $parent_id; 
	$self->{key_modified}{"Parent_Id"} = 1; 
}

sub get_editable
{
	my ($self) = shift;
	return $self->{editable}; 
}

sub set_editable
{
	my ($self,$editable) = @_;
	$self->{editable} = $editable; 
	$self->{key_modified}{"\$editable"} = 1; 
}

sub get_file_id
{
	my ($self) = shift;
	return $self->{file_id}; 
}

sub set_file_id
{
	my ($self,$file_id) = @_;
	$self->{file_id} = $file_id; 
	$self->{key_modified}{"\$file_id"} = 1; 
}

sub get_type
{
	my ($self) = shift;
	return $self->{type}; 
}

sub set_type
{
	my ($self,$type) = @_;
	$self->{type} = $type; 
	$self->{key_modified}{"\$type"} = 1; 
}

sub get_se_module
{
	my ($self) = shift;
	return $self->{se_module}; 
}

sub set_se_module
{
	my ($self,$se_module) = @_;
	$self->{se_module} = $se_module; 
	$self->{key_modified}{"\$se_module"} = 1; 
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
	$self->{key_modified}{"Modified_By"} = 1; 
}

sub get_state
{
	my ($self) = shift;
	return $self->{state}; 
}

sub set_state
{
	my ($self,$state) = @_;
	$self->{state} = $state; 
	$self->{key_modified}{"\$state"} = 1; 
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
	$self->{key_modified}{"Created_By"} = 1; 
}

sub get_link_url
{
	my ($self) = shift;
	return $self->{link_url}; 
}

sub set_link_url
{
	my ($self,$link_url) = @_;
	$self->{link_url} = $link_url; 
	$self->{key_modified}{"\$link_url"} = 1; 
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