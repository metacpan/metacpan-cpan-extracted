require 'src/com/zoho/crm/api/util/Choice.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package bulkread::RequestWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		callback => undef,
		query => undef,
		file_type => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_callback
{
	my ($self) = shift;
	return $self->{callback}; 
}

sub set_callback
{
	my ($self,$callback) = @_;
	if(!(($callback)->isa("bulkread::CallBack")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: callback EXPECTED TYPE: bulkread::CallBack", undef, undef); 
	}
	$self->{callback} = $callback; 
	$self->{key_modified}{"callback"} = 1; 
}

sub get_query
{
	my ($self) = shift;
	return $self->{query}; 
}

sub set_query
{
	my ($self,$query) = @_;
	if(!(($query)->isa("bulkread::Query")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: query EXPECTED TYPE: bulkread::Query", undef, undef); 
	}
	$self->{query} = $query; 
	$self->{key_modified}{"query"} = 1; 
}

sub get_file_type
{
	my ($self) = shift;
	return $self->{file_type}; 
}

sub set_file_type
{
	my ($self,$file_type) = @_;
	if(!(($file_type)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: file_type EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{file_type} = $file_type; 
	$self->{key_modified}{"file_type"} = 1; 
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