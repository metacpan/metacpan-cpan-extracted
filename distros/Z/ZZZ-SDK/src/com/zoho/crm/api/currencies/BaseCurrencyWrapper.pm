require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package currencies::BaseCurrencyWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		base_currency => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_base_currency
{
	my ($self) = shift;
	return $self->{base_currency}; 
}

sub set_base_currency
{
	my ($self,$base_currency) = @_;
	if(!(($base_currency)->isa("currencies::Currency")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: base_currency EXPECTED TYPE: currencies::Currency", undef, undef); 
	}
	$self->{base_currency} = $base_currency; 
	$self->{key_modified}{"base_currency"} = 1; 
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