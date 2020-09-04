require 'src/com/zoho/crm/api/users/User.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package profiles::Profile;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		display_label => undef,
		created_time => undef,
		modified_time => undef,
		permissions_details => undef,
		name => undef,
		modified_by => undef,
		default => undef,
		description => undef,
		id => undef,
		category => undef,
		created_by => undef,
		sections => undef,
		delete => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
=pod

=over 1

=item get_display_label()

The method to get the display label


=back

=cut

sub get_display_label
{
	my ($self) = shift;
	return $self->{display_label}; 
}

=pod

=over 1

=item set_display_label($display_label)

The method to set value.


=back

=cut

sub set_display_label
{
	my ($self,$display_label) = @_;
	$self->{display_label} = $display_label; 
	$self->{key_modified}{"display_label"} = 1; 
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

sub get_permissions_details
{
	my ($self) = shift;
	return $self->{permissions_details}; 
}

sub set_permissions_details
{
	my ($self,$permissions_details) = @_;
	if(!(ref($permissions_details) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: permissions_details EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{permissions_details} = $permissions_details; 
	$self->{key_modified}{"permissions_details"} = 1; 
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