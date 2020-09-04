require 'src/com/zoho/crm/api/util/Choice.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package bulkread::CallBack;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		url => undef,
		method => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_url
{
	my ($self) = shift;
	return $self->{url}; 
}

sub set_url
{
	my ($self,$url) = @_;
	$self->{url} = $url; 
	$self->{key_modified}{"url"} = 1; 
}

sub get_method
{
	my ($self) = shift;
	return $self->{method}; 
}

sub set_method
{
	my ($self,$method) = @_;
	if(!(($method)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: method EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{method} = $method; 
	$self->{key_modified}{"method"} = 1; 
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