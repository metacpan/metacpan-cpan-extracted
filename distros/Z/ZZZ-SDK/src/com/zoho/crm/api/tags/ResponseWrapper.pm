require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package tags::ResponseWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		tags => undef,
		info => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_tags
{
	my ($self) = shift;
	return $self->{tags}; 
}

sub set_tags
{
	my ($self,$tags) = @_;
	if(!(ref($tags) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: tags EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{tags} = $tags; 
	$self->{key_modified}{"tags"} = 1; 
}

sub get_info
{
	my ($self) = shift;
	return $self->{info}; 
}

sub set_info
{
	my ($self,$info) = @_;
	if(!(($info)->isa("tags::Info")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: info EXPECTED TYPE: tags::Info", undef, undef); 
	}
	$self->{info} = $info; 
	$self->{key_modified}{"info"} = 1; 
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