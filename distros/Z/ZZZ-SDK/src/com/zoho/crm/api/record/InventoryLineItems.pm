require 'src/com/zoho/crm/api/record/Record.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package record::InventoryLineItems;
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
sub get_product
{
	my ($self) = shift;
	return $self->get_key_value("product"); 
}

sub set_product
{
	my ($self,$product) = @_;
	if(!(($product)->isa("record::LineItemProduct")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: product EXPECTED TYPE: record::LineItemProduct", undef, undef); 
	}
	$self->add_key_value("product", $product); 
}

sub get_quantity
{
	my ($self) = shift;
	return $self->get_key_value("quantity"); 
}

sub set_quantity
{
	my ($self,$quantity) = @_;
	$self->add_key_value("quantity", $quantity); 
}

sub get_discount
{
	my ($self) = shift;
	return $self->get_key_value("Discount"); 
}

sub set_discount
{
	my ($self,$discount) = @_;
	$self->add_key_value("Discount", $discount); 
}

sub get_total_after_discount
{
	my ($self) = shift;
	return $self->get_key_value("total_after_discount"); 
}

sub set_total_after_discount
{
	my ($self,$total_after_discount) = @_;
	$self->add_key_value("total_after_discount", $total_after_discount); 
}

sub get_net_total
{
	my ($self) = shift;
	return $self->get_key_value("net_total"); 
}

sub set_net_total
{
	my ($self,$net_total) = @_;
	$self->add_key_value("net_total", $net_total); 
}

sub get_book
{
	my ($self) = shift;
	return $self->get_key_value("book"); 
}

sub set_book
{
	my ($self,$book) = @_;
	$self->add_key_value("book", $book); 
}

sub get_tax
{
	my ($self) = shift;
	return $self->get_key_value("Tax"); 
}

sub set_tax
{
	my ($self,$tax) = @_;
	$self->add_key_value("Tax", $tax); 
}

sub get_list_price
{
	my ($self) = shift;
	return $self->get_key_value("list_price"); 
}

sub set_list_price
{
	my ($self,$list_price) = @_;
	$self->add_key_value("list_price", $list_price); 
}

sub get_unit_price
{
	my ($self) = shift;
	return $self->get_key_value("unit_price"); 
}

sub set_unit_price
{
	my ($self,$unit_price) = @_;
	$self->add_key_value("unit_price", $unit_price); 
}

sub get_quantity_in_stock
{
	my ($self) = shift;
	return $self->get_key_value("quantity_in_stock"); 
}

sub set_quantity_in_stock
{
	my ($self,$quantity_in_stock) = @_;
	$self->add_key_value("quantity_in_stock", $quantity_in_stock); 
}

sub get_total
{
	my ($self) = shift;
	return $self->get_key_value("total"); 
}

sub set_total
{
	my ($self,$total) = @_;
	$self->add_key_value("total", $total); 
}

sub get_product_description
{
	my ($self) = shift;
	return $self->get_key_value("product_description"); 
}

sub set_product_description
{
	my ($self,$product_description) = @_;
	$self->add_key_value("product_description", $product_description); 
}

sub get_line_tax
{
	my ($self) = shift;
	return $self->get_key_value("line_tax"); 
}

sub set_line_tax
{
	my ($self,$line_tax) = @_;
	if(!(ref($line_tax) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: line_tax EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->add_key_value("line_tax", $line_tax); 
}
1;