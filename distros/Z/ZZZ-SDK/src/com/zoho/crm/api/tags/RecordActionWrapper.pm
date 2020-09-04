require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package tags::RecordActionWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		data => undef,
		wf_scheduler => undef,
		success_count => undef,
		locked_count => undef,
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

sub get_wf_scheduler
{
	my ($self) = shift;
	return $self->{wf_scheduler}; 
}

sub set_wf_scheduler
{
	my ($self,$wf_scheduler) = @_;
	$self->{wf_scheduler} = $wf_scheduler; 
	$self->{key_modified}{"wf_scheduler"} = 1; 
}

sub get_success_count
{
	my ($self) = shift;
	return $self->{success_count}; 
}

sub set_success_count
{
	my ($self,$success_count) = @_;
	$self->{success_count} = $success_count; 
	$self->{key_modified}{"success_count"} = 1; 
}

sub get_locked_count
{
	my ($self) = shift;
	return $self->{locked_count}; 
}

sub set_locked_count
{
	my ($self,$locked_count) = @_;
	$self->{locked_count} = $locked_count; 
	$self->{key_modified}{"locked_count"} = 1; 
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