require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package blueprint::ResponseWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		blueprint => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_blueprint
{
	my ($self) = shift;
	return $self->{blueprint}; 
}

sub set_blueprint
{
	my ($self,$blueprint) = @_;
	if(!(($blueprint)->isa("blueprint::BluePrint")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: blueprint EXPECTED TYPE: blueprint::BluePrint", undef, undef); 
	}
	$self->{blueprint} = $blueprint; 
	$self->{key_modified}{"blueprint"} = 1; 
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