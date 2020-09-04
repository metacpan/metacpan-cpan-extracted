require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package variables::BodyWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		variables => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_variables
{
	my ($self) = shift;
	return $self->{variables}; 
}

sub set_variables
{
	my ($self,$variables) = @_;
	if(!(ref($variables) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: variables EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{variables} = $variables; 
	$self->{key_modified}{"variables"} = 1; 
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