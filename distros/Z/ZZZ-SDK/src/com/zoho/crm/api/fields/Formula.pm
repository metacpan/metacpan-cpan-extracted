require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package fields::Formula;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		return_type => undef,
		expression => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_return_type
{
	my ($self) = shift;
	return $self->{return_type}; 
}

sub set_return_type
{
	my ($self,$return_type) = @_;
	$self->{return_type} = $return_type; 
	$self->{key_modified}{"return_type"} = 1; 
}

sub get_expression
{
	my ($self) = shift;
	return $self->{expression}; 
}

sub set_expression
{
	my ($self,$expression) = @_;
	$self->{expression} = $expression; 
	$self->{key_modified}{"expression"} = 1; 
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