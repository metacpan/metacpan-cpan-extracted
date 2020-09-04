require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package bulkwrite::Result;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		download_url => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_download_url
{
	my ($self) = shift;
	return $self->{download_url}; 
}

sub set_download_url
{
	my ($self,$download_url) = @_;
	$self->{download_url} = $download_url; 
	$self->{key_modified}{"download_url"} = 1; 
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