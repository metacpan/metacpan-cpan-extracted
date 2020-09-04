require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package fields::AutoNumber;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		prefix => undef,
		suffix => undef,
		start_number => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_prefix
{
	my ($self) = shift;
	return $self->{prefix}; 
}

sub set_prefix
{
	my ($self,$prefix) = @_;
	$self->{prefix} = $prefix; 
	$self->{key_modified}{"prefix"} = 1; 
}

sub get_suffix
{
	my ($self) = shift;
	return $self->{suffix}; 
}

sub set_suffix
{
	my ($self,$suffix) = @_;
	$self->{suffix} = $suffix; 
	$self->{key_modified}{"suffix"} = 1; 
}

sub get_start_number
{
	my ($self) = shift;
	return $self->{start_number}; 
}

sub set_start_number
{
	my ($self,$start_number) = @_;
	$self->{start_number} = $start_number; 
	$self->{key_modified}{"start_number"} = 1; 
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