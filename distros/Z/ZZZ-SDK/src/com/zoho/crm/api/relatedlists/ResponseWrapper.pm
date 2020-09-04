require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package relatedlists::ResponseWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		related_lists => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_related_lists
{
	my ($self) = shift;
	return $self->{related_lists}; 
}

sub set_related_lists
{
	my ($self,$related_lists) = @_;
	if(!(ref($related_lists) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: related_lists EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{related_lists} = $related_lists; 
	$self->{key_modified}{"related_lists"} = 1; 
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