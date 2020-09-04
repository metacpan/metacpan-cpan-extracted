require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package taxes::ActionWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		taxes => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_taxes
{
	my ($self) = shift;
	return $self->{taxes}; 
}

sub set_taxes
{
	my ($self,$taxes) = @_;
	if(!(ref($taxes) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: taxes EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{taxes} = $taxes; 
	$self->{key_modified}{"taxes"} = 1; 
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