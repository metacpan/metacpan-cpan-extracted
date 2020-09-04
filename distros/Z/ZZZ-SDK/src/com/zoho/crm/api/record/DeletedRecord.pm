require 'src/com/zoho/crm/api/users/User.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package record::DeletedRecord;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		deleted_by => undef,
		id => undef,
		display_name => undef,
		type => undef,
		created_by => undef,
		deleted_time => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_deleted_by
{
	my ($self) = shift;
	return $self->{deleted_by}; 
}

sub set_deleted_by
{
	my ($self,$deleted_by) = @_;
	if(!(($deleted_by)->isa("users::User")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: deleted_by EXPECTED TYPE: users::User", undef, undef); 
	}
	$self->{deleted_by} = $deleted_by; 
	$self->{key_modified}{"deleted_by"} = 1; 
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

sub get_display_name
{
	my ($self) = shift;
	return $self->{display_name}; 
}

sub set_display_name
{
	my ($self,$display_name) = @_;
	$self->{display_name} = $display_name; 
	$self->{key_modified}{"display_name"} = 1; 
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
	$self->{key_modified}{"type"} = 1; 
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

sub get_deleted_time
{
	my ($self) = shift;
	return $self->{deleted_time}; 
}

sub set_deleted_time
{
	my ($self,$deleted_time) = @_;
	if(!(($deleted_time)->isa("DateTime")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: deleted_time EXPECTED TYPE: DateTime", undef, undef); 
	}
	$self->{deleted_time} = $deleted_time; 
	$self->{key_modified}{"deleted_time"} = 1; 
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