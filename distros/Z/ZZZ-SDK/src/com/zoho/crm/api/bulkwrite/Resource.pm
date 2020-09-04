require 'src/com/zoho/crm/api/util/Choice.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package bulkwrite::Resource;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		status => undef,
		type => undef,
		module => undef,
		file_id => undef,
		ignore_empty => undef,
		find_by => undef,
		field_mappings => undef,
		file => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_status
{
	my ($self) = shift;
	return $self->{status}; 
}

sub set_status
{
	my ($self,$status) = @_;
	if(!(($status)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: status EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{status} = $status; 
	$self->{key_modified}{"status"} = 1; 
}

sub get_type
{
	my ($self) = shift;
	return $self->{type}; 
}

sub set_type
{
	my ($self,$type) = @_;
	if(!(($type)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: type EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{type} = $type; 
	$self->{key_modified}{"type"} = 1; 
}

sub get_module
{
	my ($self) = shift;
	return $self->{module}; 
}

sub set_module
{
	my ($self,$module) = @_;
	$self->{module} = $module; 
	$self->{key_modified}{"module"} = 1; 
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
	$self->{key_modified}{"file_id"} = 1; 
}

sub get_ignore_empty
{
	my ($self) = shift;
	return $self->{ignore_empty}; 
}

sub set_ignore_empty
{
	my ($self,$ignore_empty) = @_;
	$self->{ignore_empty} = $ignore_empty; 
	$self->{key_modified}{"ignore_empty"} = 1; 
}

sub get_find_by
{
	my ($self) = shift;
	return $self->{find_by}; 
}

sub set_find_by
{
	my ($self,$find_by) = @_;
	$self->{find_by} = $find_by; 
	$self->{key_modified}{"find_by"} = 1; 
}

sub get_field_mappings
{
	my ($self) = shift;
	return $self->{field_mappings}; 
}

sub set_field_mappings
{
	my ($self,$field_mappings) = @_;
	if(!(ref($field_mappings) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: field_mappings EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{field_mappings} = $field_mappings; 
	$self->{key_modified}{"field_mappings"} = 1; 
}

sub get_file
{
	my ($self) = shift;
	return $self->{file}; 
}

sub set_file
{
	my ($self,$file) = @_;
	if(!(($file)->isa("bulkwrite::File")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: file EXPECTED TYPE: bulkwrite::File", undef, undef); 
	}
	$self->{file} = $file; 
	$self->{key_modified}{"file"} = 1; 
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