require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package variablegroups::ResponseWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		variable_groups => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_variable_groups
{
	my ($self) = shift;
	return $self->{variable_groups}; 
}

sub set_variable_groups
{
	my ($self,$variable_groups) = @_;
	if(!(ref($variable_groups) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: variable_groups EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{variable_groups} = $variable_groups; 
	$self->{key_modified}{"variable_groups"} = 1; 
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