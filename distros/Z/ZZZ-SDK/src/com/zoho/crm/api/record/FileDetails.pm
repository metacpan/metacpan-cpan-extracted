require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package record::FileDetails;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		extn => undef,
		is_preview_available => undef,
		download_url => undef,
		delete_url => undef,
		entity_id => undef,
		mode => undef,
		original_size_byte => undef,
		preview_url => undef,
		file_name => undef,
		file_id => undef,
		attachment_id => undef,
		file_size => undef,
		creator_id => undef,
		link_docs => undef,
		delete => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_extn
{
	my ($self) = shift;
	return $self->{extn}; 
}

sub set_extn
{
	my ($self,$extn) = @_;
	$self->{extn} = $extn; 
	$self->{key_modified}{"extn"} = 1; 
}

sub get_is_preview_available
{
	my ($self) = shift;
	return $self->{is_preview_available}; 
}

sub set_is_preview_available
{
	my ($self,$is_preview_available) = @_;
	$self->{is_preview_available} = $is_preview_available; 
	$self->{key_modified}{"is_Preview_Available"} = 1; 
}

sub get_download_url
{
	my ($self) = shift;
	return $self->{download_url}; 
}

sub set_download_url
{
	my ($self,$download_url) = @_;
	$self->{download_url} = $download_url; 
	$self->{key_modified}{"download_Url"} = 1; 
}

sub get_delete_url
{
	my ($self) = shift;
	return $self->{delete_url}; 
}

sub set_delete_url
{
	my ($self,$delete_url) = @_;
	$self->{delete_url} = $delete_url; 
	$self->{key_modified}{"delete_Url"} = 1; 
}

sub get_entity_id
{
	my ($self) = shift;
	return $self->{entity_id}; 
}

sub set_entity_id
{
	my ($self,$entity_id) = @_;
	$self->{entity_id} = $entity_id; 
	$self->{key_modified}{"entity_Id"} = 1; 
}

sub get_mode
{
	my ($self) = shift;
	return $self->{mode}; 
}

sub set_mode
{
	my ($self,$mode) = @_;
	$self->{mode} = $mode; 
	$self->{key_modified}{"mode"} = 1; 
}

sub get_original_size_byte
{
	my ($self) = shift;
	return $self->{original_size_byte}; 
}

sub set_original_size_byte
{
	my ($self,$original_size_byte) = @_;
	$self->{original_size_byte} = $original_size_byte; 
	$self->{key_modified}{"original_Size_Byte"} = 1; 
}

sub get_preview_url
{
	my ($self) = shift;
	return $self->{preview_url}; 
}

sub set_preview_url
{
	my ($self,$preview_url) = @_;
	$self->{preview_url} = $preview_url; 
	$self->{key_modified}{"preview_Url"} = 1; 
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
	$self->{key_modified}{"file_Name"} = 1; 
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
	$self->{key_modified}{"file_Id"} = 1; 
}

sub get_attachment_id
{
	my ($self) = shift;
	return $self->{attachment_id}; 
}

sub set_attachment_id
{
	my ($self,$attachment_id) = @_;
	$self->{attachment_id} = $attachment_id; 
	$self->{key_modified}{"attachment_Id"} = 1; 
}

sub get_file_size
{
	my ($self) = shift;
	return $self->{file_size}; 
}

sub set_file_size
{
	my ($self,$file_size) = @_;
	$self->{file_size} = $file_size; 
	$self->{key_modified}{"file_Size"} = 1; 
}

sub get_creator_id
{
	my ($self) = shift;
	return $self->{creator_id}; 
}

sub set_creator_id
{
	my ($self,$creator_id) = @_;
	$self->{creator_id} = $creator_id; 
	$self->{key_modified}{"creator_Id"} = 1; 
}

sub get_link_docs
{
	my ($self) = shift;
	return $self->{link_docs}; 
}

sub set_link_docs
{
	my ($self,$link_docs) = @_;
	$self->{link_docs} = $link_docs; 
	$self->{key_modified}{"link_Docs"} = 1; 
}

sub get_delete
{
	my ($self) = shift;
	return $self->{delete}; 
}

sub set_delete
{
	my ($self,$delete) = @_;
	$self->{delete} = $delete; 
	$self->{key_modified}{"_delete"} = 1; 
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