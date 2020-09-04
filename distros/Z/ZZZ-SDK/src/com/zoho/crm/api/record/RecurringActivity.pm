require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package record::RecurringActivity;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		rrule => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_rrule
{
	my ($self) = shift;
	return $self->{rrule}; 
}

sub set_rrule
{
	my ($self,$rrule) = @_;
	$self->{rrule} = $rrule; 
	$self->{key_modified}{"RRULE"} = 1; 
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