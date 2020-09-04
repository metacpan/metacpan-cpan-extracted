require 'src/com/zoho/crm/api/record/Record.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package blueprint::BluePrint;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		transition_id => undef,
		data => undef,
		process_info => undef,
		transitions => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_transition_id
{
	my ($self) = shift;
	return $self->{transition_id}; 
}

sub set_transition_id
{
	my ($self,$transition_id) = @_;
	$self->{transition_id} = $transition_id; 
	$self->{key_modified}{"transition_id"} = 1; 
}

sub get_data
{
	my ($self) = shift;
	return $self->{data}; 
}

sub set_data
{
	my ($self,$data) = @_;
	if(!(($data)->isa("record::Record")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: data EXPECTED TYPE: record::Record", undef, undef); 
	}
	$self->{data} = $data; 
	$self->{key_modified}{"data"} = 1; 
}

sub get_process_info
{
	my ($self) = shift;
	return $self->{process_info}; 
}

sub set_process_info
{
	my ($self,$process_info) = @_;
	if(!(($process_info)->isa("blueprint::ProcessInfo")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: process_info EXPECTED TYPE: blueprint::ProcessInfo", undef, undef); 
	}
	$self->{process_info} = $process_info; 
	$self->{key_modified}{"process_info"} = 1; 
}

sub get_transitions
{
	my ($self) = shift;
	return $self->{transitions}; 
}

sub set_transitions
{
	my ($self,$transitions) = @_;
	if(!(ref($transitions) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: transitions EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{transitions} = $transitions; 
	$self->{key_modified}{"transitions"} = 1; 
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