require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package bulkread::Result;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		page => undef,
		count => undef,
		download_url => undef,
		per_page => undef,
		more_records => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_page
{
	my ($self) = shift;
	return $self->{page}; 
}

sub set_page
{
	my ($self,$page) = @_;
	$self->{page} = $page; 
	$self->{key_modified}{"page"} = 1; 
}

sub get_count
{
	my ($self) = shift;
	return $self->{count}; 
}

sub set_count
{
	my ($self,$count) = @_;
	$self->{count} = $count; 
	$self->{key_modified}{"count"} = 1; 
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

sub get_per_page
{
	my ($self) = shift;
	return $self->{per_page}; 
}

sub set_per_page
{
	my ($self,$per_page) = @_;
	$self->{per_page} = $per_page; 
	$self->{key_modified}{"per_page"} = 1; 
}

sub get_more_records
{
	my ($self) = shift;
	return $self->{more_records}; 
}

sub set_more_records
{
	my ($self,$more_records) = @_;
	$self->{more_records} = $more_records; 
	$self->{key_modified}{"more_records"} = 1; 
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