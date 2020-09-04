require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package layouts::ResponseWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		layouts => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_layouts
{
	my ($self) = shift;
	return $self->{layouts}; 
}

sub set_layouts
{
	my ($self,$layouts) = @_;
	if(!(ref($layouts) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: layouts EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{layouts} = $layouts; 
	$self->{key_modified}{"layouts"} = 1; 
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