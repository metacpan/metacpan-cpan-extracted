require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package taxes::Tax;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		display_label => undef,
		name => undef,
		id => undef,
		value => undef,
		sequence_number => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_display_label
{
	my ($self) = shift;
	return $self->{display_label}; 
}

sub set_display_label
{
	my ($self,$display_label) = @_;
	$self->{display_label} = $display_label; 
	$self->{key_modified}{"display_label"} = 1; 
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

sub get_value
{
	my ($self) = shift;
	return $self->{value}; 
}

sub set_value
{
	my ($self,$value) = @_;
	$self->{value} = $value; 
	$self->{key_modified}{"value"} = 1; 
}

sub get_sequence_number
{
	my ($self) = shift;
	return $self->{sequence_number}; 
}

sub set_sequence_number
{
	my ($self,$sequence_number) = @_;
	$self->{sequence_number} = $sequence_number; 
	$self->{key_modified}{"sequence_number"} = 1; 
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