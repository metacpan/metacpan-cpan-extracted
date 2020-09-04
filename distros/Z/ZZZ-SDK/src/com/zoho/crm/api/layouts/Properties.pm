require 'src/com/zoho/crm/api/fields/ToolTip.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package layouts::Properties;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		reorder_rows => undef,
		tooltip => undef,
		maximum_rows => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_reorder_rows
{
	my ($self) = shift;
	return $self->{reorder_rows}; 
}

sub set_reorder_rows
{
	my ($self,$reorder_rows) = @_;
	$self->{reorder_rows} = $reorder_rows; 
	$self->{key_modified}{"reorder_rows"} = 1; 
}

sub get_tooltip
{
	my ($self) = shift;
	return $self->{tooltip}; 
}

sub set_tooltip
{
	my ($self,$tooltip) = @_;
	if(!(($tooltip)->isa("fields::ToolTip")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: tooltip EXPECTED TYPE: fields::ToolTip", undef, undef); 
	}
	$self->{tooltip} = $tooltip; 
	$self->{key_modified}{"tooltip"} = 1; 
}

sub get_maximum_rows
{
	my ($self) = shift;
	return $self->{maximum_rows}; 
}

sub set_maximum_rows
{
	my ($self,$maximum_rows) = @_;
	$self->{maximum_rows} = $maximum_rows; 
	$self->{key_modified}{"maximum_rows"} = 1; 
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