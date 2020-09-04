require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package profiles::Section;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		name => undef,
		categories => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_name
{
	my ($self) = shift;
	return $self->{name}; 
}

sub set_name
{
	my ($self,$name) = @_;
	$self->{name} = $name; 
	$self->{key_modified}{"name"} = 1; 
}

sub get_categories
{
	my ($self) = shift;
	return $self->{categories}; 
}

sub set_categories
{
	my ($self,$categories) = @_;
	if(!(ref($categories) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: categories EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{categories} = $categories; 
	$self->{key_modified}{"categories"} = 1; 
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