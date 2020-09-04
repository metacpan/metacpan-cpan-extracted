require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package fields::ToolTip;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		name => undef,
		value => undef,
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

sub get_value
{
	my ($self) = shift;
	return $self->{value}; 
}

sub set_value
{
	my ($self,$value) = @_;
	$self->{value} = $value; 
	$self->{key_modified}{"value"} = 1; 
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