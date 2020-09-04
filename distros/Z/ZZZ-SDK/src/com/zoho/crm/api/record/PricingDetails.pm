require 'src/com/zoho/crm/api/record/Record.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package record::PricingDetails;
use Moose;
our @ISA = qw (record::Record );

sub new
{
	my ($class) = shift;
	my $self = 
	{
	};
	bless $self,$class;
	return $self;
}
sub get_to_range
{
	my ($self) = shift;
	return $self->get_key_value("to_range"); 
}

sub set_to_range
{
	my ($self,$to_range) = @_;
	$self->add_key_value("to_range", $to_range); 
}

sub get_discount
{
	my ($self) = shift;
	return $self->get_key_value("discount"); 
}

sub set_discount
{
	my ($self,$discount) = @_;
	$self->add_key_value("discount", $discount); 
}

sub get_from_range
{
	my ($self) = shift;
	return $self->get_key_value("from_range"); 
}

sub set_from_range
{
	my ($self,$from_range) = @_;
	$self->add_key_value("from_range", $from_range); 
}
1;