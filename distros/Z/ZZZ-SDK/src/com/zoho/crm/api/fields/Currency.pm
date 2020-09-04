require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package fields::Currency;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		rounding_option => undef,
		precision => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_rounding_option
{
	my ($self) = shift;
	return $self->{rounding_option}; 
}

sub set_rounding_option
{
	my ($self,$rounding_option) = @_;
	$self->{rounding_option} = $rounding_option; 
	$self->{key_modified}{"rounding_option"} = 1; 
}

sub get_precision
{
	my ($self) = shift;
	return $self->{precision}; 
}

sub set_precision
{
	my ($self,$precision) = @_;
	$self->{precision} = $precision; 
	$self->{key_modified}{"precision"} = 1; 
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