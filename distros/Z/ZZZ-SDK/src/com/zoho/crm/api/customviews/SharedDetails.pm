require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package customviews::SharedDetails;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		id => undef,
		name => undef,
		type => undef,
		subordinates => undef,
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

sub get_subordinates
{
	my ($self) = shift;
	return $self->{subordinates}; 
}

sub set_subordinates
{
	my ($self,$subordinates) = @_;
	$self->{subordinates} = $subordinates; 
	$self->{key_modified}{"subordinates"} = 1; 
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