require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package bulkwrite::FieldMapping;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		api_name => undef,
		index => undef,
		format => undef,
		find_by => undef,
		default_value => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_api_name
{
	my ($self) = shift;
	return $self->{api_name}; 
}

sub set_api_name
{
	my ($self,$api_name) = @_;
	$self->{api_name} = $api_name; 
	$self->{key_modified}{"api_name"} = 1; 
}

sub get_index
{
	my ($self) = shift;
	return $self->{index}; 
}

sub set_index
{
	my ($self,$index) = @_;
	$self->{index} = $index; 
	$self->{key_modified}{"index"} = 1; 
}

sub get_format
{
	my ($self) = shift;
	return $self->{format}; 
}

sub set_format
{
	my ($self,$format) = @_;
	$self->{format} = $format; 
	$self->{key_modified}{"format"} = 1; 
}

sub get_find_by
{
	my ($self) = shift;
	return $self->{find_by}; 
}

sub set_find_by
{
	my ($self,$find_by) = @_;
	$self->{find_by} = $find_by; 
	$self->{key_modified}{"find_by"} = 1; 
}

sub get_default_value
{
	my ($self) = shift;
	return $self->{default_value}; 
}

sub set_default_value
{
	my ($self,$default_value) = @_;
	if(!(ref($default_value) eq "HASH"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: default_value EXPECTED TYPE: HASH", undef, undef); 
	}
	$self->{default_value} = $default_value; 
	$self->{key_modified}{"default_value"} = 1; 
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