require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package customviews::ResponseWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		custom_views => undef,
		info => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_custom_views
{
	my ($self) = shift;
	return $self->{custom_views}; 
}

sub set_custom_views
{
	my ($self,$custom_views) = @_;
	if(!(ref($custom_views) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: custom_views EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{custom_views} = $custom_views; 
	$self->{key_modified}{"custom_views"} = 1; 
}

sub get_info
{
	my ($self) = shift;
	return $self->{info}; 
}

sub set_info
{
	my ($self,$info) = @_;
	if(!(($info)->isa("customviews::Info")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: info EXPECTED TYPE: customviews::Info", undef, undef); 
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