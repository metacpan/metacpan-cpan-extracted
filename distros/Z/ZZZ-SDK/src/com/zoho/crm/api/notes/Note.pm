require 'src/com/zoho/crm/api/attachments/Attachment.pm';
require 'src/com/zoho/crm/api/record/Record.pm';
require 'src/com/zoho/crm/api/users/User.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package notes::Note;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		owner => undef,
		modified_time => undef,
		attachments => undef,
		created_time => undef,
		parent_id => undef,
		editable => undef,
		se_module => undef,
		is_shared_to_client => undef,
		modified_by => undef,
		size => undef,
		state => undef,
		voice_note => undef,
		id => undef,
		created_by => undef,
		note_title => undef,
		note_content => undef,
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

sub get_attachments
{
	my ($self) = shift;
	return $self->{attachments}; 
}

sub set_attachments
{
	my ($self,$attachments) = @_;
	if(!(ref($attachments) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: attachments EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{attachments} = $attachments; 
	$self->{key_modified}{"\$attachments"} = 1; 
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

sub get_is_shared_to_client
{
	my ($self) = shift;
	return $self->{is_shared_to_client}; 
}

sub set_is_shared_to_client
{
	my ($self,$is_shared_to_client) = @_;
	$self->{is_shared_to_client} = $is_shared_to_client; 
	$self->{key_modified}{"\$is_shared_to_client"} = 1; 
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

sub get_size
{
	my ($self) = shift;
	return $self->{size}; 
}

sub set_size
{
	my ($self,$size) = @_;
	$self->{size} = $size; 
	$self->{key_modified}{"\$size"} = 1; 
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

sub get_voice_note
{
	my ($self) = shift;
	return $self->{voice_note}; 
}

sub set_voice_note
{
	my ($self,$voice_note) = @_;
	$self->{voice_note} = $voice_note; 
	$self->{key_modified}{"\$voice_note"} = 1; 
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

sub get_note_title
{
	my ($self) = shift;
	return $self->{note_title}; 
}

sub set_note_title
{
	my ($self,$note_title) = @_;
	$self->{note_title} = $note_title; 
	$self->{key_modified}{"Note_Title"} = 1; 
}

sub get_note_content
{
	my ($self) = shift;
	return $self->{note_content}; 
}

sub set_note_content
{
	my ($self,$note_content) = @_;
	$self->{note_content} = $note_content; 
	$self->{key_modified}{"Note_Content"} = 1; 
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