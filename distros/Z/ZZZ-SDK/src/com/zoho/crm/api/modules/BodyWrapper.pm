require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package modules::BodyWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		modules => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_modules
{
	my ($self) = shift;
	return $self->{modules}; 
}

sub set_modules
{
	my ($self,$modules) = @_;
	if(!(ref($modules) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: modules EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{modules} = $modules; 
	$self->{key_modified}{"modules"} = 1; 
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