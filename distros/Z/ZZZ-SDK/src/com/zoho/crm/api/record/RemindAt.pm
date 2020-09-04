require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package record::RemindAt;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		alarm => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_alarm
{
	my ($self) = shift;
	return $self->{alarm}; 
}

sub set_alarm
{
	my ($self,$alarm) = @_;
	$self->{alarm} = $alarm; 
	$self->{key_modified}{"ALARM"} = 1; 
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