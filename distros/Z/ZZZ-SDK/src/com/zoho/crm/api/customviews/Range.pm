require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package customviews::Range;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		from => undef,
		to => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_from
{
	my ($self) = shift;
	return $self->{from}; 
}

sub set_from
{
	my ($self,$from) = @_;
	$self->{from} = $from; 
	$self->{key_modified}{"from"} = 1; 
}

sub get_to
{
	my ($self) = shift;
	return $self->{to}; 
}

sub set_to
{
	my ($self,$to) = @_;
	$self->{to} = $to; 
	$self->{key_modified}{"to"} = 1; 
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