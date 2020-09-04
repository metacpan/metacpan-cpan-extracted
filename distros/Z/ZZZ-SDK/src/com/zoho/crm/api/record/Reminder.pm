require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package record::Reminder;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		period => undef,
		unit => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_period
{
	my ($self) = shift;
	return $self->{period}; 
}

sub set_period
{
	my ($self,$period) = @_;
	$self->{period} = $period; 
	$self->{key_modified}{"period"} = 1; 
}

sub get_unit
{
	my ($self) = shift;
	return $self->{unit}; 
}

sub set_unit
{
	my ($self,$unit) = @_;
	$self->{unit} = $unit; 
	$self->{key_modified}{"unit"} = 1; 
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