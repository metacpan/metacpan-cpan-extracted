require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package fields::PickListValue;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		display_value => undef,
		sequence_number => undef,
		expected_data_type => undef,
		maps => undef,
		actual_value => undef,
		sys_ref_name => undef,
		type => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_display_value
{
	my ($self) = shift;
	return $self->{display_value}; 
}

sub set_display_value
{
	my ($self,$display_value) = @_;
	$self->{display_value} = $display_value; 
	$self->{key_modified}{"display_value"} = 1; 
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

sub get_expected_data_type
{
	my ($self) = shift;
	return $self->{expected_data_type}; 
}

sub set_expected_data_type
{
	my ($self,$expected_data_type) = @_;
	$self->{expected_data_type} = $expected_data_type; 
	$self->{key_modified}{"expected_data_type"} = 1; 
}

sub get_maps
{
	my ($self) = shift;
	return $self->{maps}; 
}

sub set_maps
{
	my ($self,$maps) = @_;
	if(!(ref($maps) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: maps EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{maps} = $maps; 
	$self->{key_modified}{"maps"} = 1; 
}

sub get_actual_value
{
	my ($self) = shift;
	return $self->{actual_value}; 
}

sub set_actual_value
{
	my ($self,$actual_value) = @_;
	$self->{actual_value} = $actual_value; 
	$self->{key_modified}{"actual_value"} = 1; 
}

sub get_sys_ref_name
{
	my ($self) = shift;
	return $self->{sys_ref_name}; 
}

sub set_sys_ref_name
{
	my ($self,$sys_ref_name) = @_;
	$self->{sys_ref_name} = $sys_ref_name; 
	$self->{key_modified}{"sys_ref_name"} = 1; 
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