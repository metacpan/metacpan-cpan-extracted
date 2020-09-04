require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package record::MassUpdateResponseWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		data => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_data
{
	my ($self) = shift;
	return $self->{data}; 
}

sub set_data
{
	my ($self,$data) = @_;
	if(!(ref($data) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: data EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{data} = $data; 
	$self->{key_modified}{"data"} = 1; 
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