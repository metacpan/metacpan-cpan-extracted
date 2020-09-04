require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package record::BodyWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		data => undef,
		trigger => undef,
		process => undef,
		duplicate_check_fields => undef,
		wf_trigger => undef,
		lar_id => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_data
{
	my ($self) = shift;
	return $self->{data}; 
}

sub set_data
{
	my ($self,$data) = @_;
	if(!(ref($data) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: data EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{data} = $data; 
	$self->{key_modified}{"data"} = 1; 
}

sub get_trigger
{
	my ($self) = shift;
	return $self->{trigger}; 
}

sub set_trigger
{
	my ($self,$trigger) = @_;
	if(!(ref($trigger) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: trigger EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{trigger} = $trigger; 
	$self->{key_modified}{"trigger"} = 1; 
}

sub get_process
{
	my ($self) = shift;
	return $self->{process}; 
}

sub set_process
{
	my ($self,$process) = @_;
	if(!(ref($process) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: process EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{process} = $process; 
	$self->{key_modified}{"process"} = 1; 
}

sub get_duplicate_check_fields
{
	my ($self) = shift;
	return $self->{duplicate_check_fields}; 
}

sub set_duplicate_check_fields
{
	my ($self,$duplicate_check_fields) = @_;
	if(!(ref($duplicate_check_fields) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: duplicate_check_fields EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{duplicate_check_fields} = $duplicate_check_fields; 
	$self->{key_modified}{"duplicate_check_fields"} = 1; 
}

sub get_wf_trigger
{
	my ($self) = shift;
	return $self->{wf_trigger}; 
}

sub set_wf_trigger
{
	my ($self,$wf_trigger) = @_;
	$self->{wf_trigger} = $wf_trigger; 
	$self->{key_modified}{"wf_trigger"} = 1; 
}

sub get_lar_id
{
	my ($self) = shift;
	return $self->{lar_id}; 
}

sub set_lar_id
{
	my ($self,$lar_id) = @_;
	$self->{lar_id} = $lar_id; 
	$self->{key_modified}{"lar_id"} = 1; 
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