require 'src/com/zoho/crm/api/util/Choice.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package currencies::Format;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		decimal_separator => undef,
		thousand_separator => undef,
		decimal_places => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_decimal_separator
{
	my ($self) = shift;
	return $self->{decimal_separator}; 
}

sub set_decimal_separator
{
	my ($self,$decimal_separator) = @_;
	if(!(($decimal_separator)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: decimal_separator EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{decimal_separator} = $decimal_separator; 
	$self->{key_modified}{"decimal_separator"} = 1; 
}

sub get_thousand_separator
{
	my ($self) = shift;
	return $self->{thousand_separator}; 
}

sub set_thousand_separator
{
	my ($self,$thousand_separator) = @_;
	if(!(($thousand_separator)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: thousand_separator EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{thousand_separator} = $thousand_separator; 
	$self->{key_modified}{"thousand_separator"} = 1; 
}

sub get_decimal_places
{
	my ($self) = shift;
	return $self->{decimal_places}; 
}

sub set_decimal_places
{
	my ($self,$decimal_places) = @_;
	if(!(($decimal_places)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: decimal_places EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{decimal_places} = $decimal_places; 
	$self->{key_modified}{"decimal_places"} = 1; 
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