require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package fields::Unique;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		casesensitive => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_casesensitive
{
	my ($self) = shift;
	return $self->{casesensitive}; 
}

sub set_casesensitive
{
	my ($self,$casesensitive) = @_;
	$self->{casesensitive} = $casesensitive; 
	$self->{key_modified}{"casesensitive"} = 1; 
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