require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package territories::ResponseWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		territories => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_territories
{
	my ($self) = shift;
	return $self->{territories}; 
}

sub set_territories
{
	my ($self,$territories) = @_;
	if(!(ref($territories) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: territories EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{territories} = $territories; 
	$self->{key_modified}{"territories"} = 1; 
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