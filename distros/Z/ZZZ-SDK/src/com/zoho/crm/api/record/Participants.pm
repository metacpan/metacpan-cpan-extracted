require 'src/com/zoho/crm/api/record/Record.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package record::Participants;
use Moose;
our @ISA = qw (record::Record );

sub new
{
	my ($class) = shift;
	my $self = 
	{
	};
	bless $self,$class;
	return $self;
}
sub get_name
{
	my ($self) = shift;
	return $self->get_key_value("name"); 
}

sub set_name
{
	my ($self,$name) = @_;
	$self->add_key_value("name", $name); 
}

sub get_invited
{
	my ($self) = shift;
	return $self->get_key_value("invited"); 
}

sub set_invited
{
	my ($self,$invited) = @_;
	$self->add_key_value("invited", $invited); 
}

sub get_type
{
	my ($self) = shift;
	return $self->get_key_value("type"); 
}

sub set_type
{
	my ($self,$type) = @_;
	$self->add_key_value("type", $type); 
}

sub get_participant
{
	my ($self) = shift;
	return $self->get_key_value("participant"); 
}

sub set_participant
{
	my ($self,$participant) = @_;
	$self->add_key_value("participant", $participant); 
}

sub get_status
{
	my ($self) = shift;
	return $self->get_key_value("status"); 
}

sub set_status
{
	my ($self,$status) = @_;
	$self->add_key_value("status", $status); 
}
1;