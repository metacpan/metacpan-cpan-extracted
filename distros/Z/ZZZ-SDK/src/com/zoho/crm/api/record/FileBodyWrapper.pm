require 'src/com/zoho/crm/api/util/StreamWrapper.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package record::FileBodyWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		file => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_file
{
	my ($self) = shift;
	return $self->{file}; 
}

sub set_file
{
	my ($self,$file) = @_;
	if(!(($file)->isa("StreamWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: file EXPECTED TYPE: StreamWrapper", undef, undef); 
	}
	$self->{file} = $file; 
	$self->{key_modified}{"file"} = 1; 
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