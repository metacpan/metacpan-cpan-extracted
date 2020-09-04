require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package customviews::Info;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		per_page => undef,
		default => undef,
		count => undef,
		page => undef,
		more_records => undef,
		translation => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
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

sub get_default
{
	my ($self) = shift;
	return $self->{default}; 
}

sub set_default
{
	my ($self,$default) = @_;
	$self->{default} = $default; 
	$self->{key_modified}{"default"} = 1; 
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

sub get_translation
{
	my ($self) = shift;
	return $self->{translation}; 
}

sub set_translation
{
	my ($self,$translation) = @_;
	if(!(($translation)->isa("customviews::Translation")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: translation EXPECTED TYPE: customviews::Translation", undef, undef); 
	}
	$self->{translation} = $translation; 
	$self->{key_modified}{"translation"} = 1; 
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