require 'src/com/zoho/crm/api/util/Choice.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package record::MassUpdate;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		status => undef,
		failed_count => undef,
		updated_count => undef,
		not_updated_count => undef,
		total_count => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_status
{
	my ($self) = shift;
	return $self->{status}; 
}

sub set_status
{
	my ($self,$status) = @_;
	if(!(($status)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: status EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{status} = $status; 
	$self->{key_modified}{"Status"} = 1; 
}

sub get_failed_count
{
	my ($self) = shift;
	return $self->{failed_count}; 
}

sub set_failed_count
{
	my ($self,$failed_count) = @_;
	$self->{failed_count} = $failed_count; 
	$self->{key_modified}{"Failed_Count"} = 1; 
}

sub get_updated_count
{
	my ($self) = shift;
	return $self->{updated_count}; 
}

sub set_updated_count
{
	my ($self,$updated_count) = @_;
	$self->{updated_count} = $updated_count; 
	$self->{key_modified}{"Updated_Count"} = 1; 
}

sub get_not_updated_count
{
	my ($self) = shift;
	return $self->{not_updated_count}; 
}

sub set_not_updated_count
{
	my ($self,$not_updated_count) = @_;
	$self->{not_updated_count} = $not_updated_count; 
	$self->{key_modified}{"Not_Updated_Count"} = 1; 
}

sub get_total_count
{
	my ($self) = shift;
	return $self->{total_count}; 
}

sub set_total_count
{
	my ($self,$total_count) = @_;
	$self->{total_count} = $total_count; 
	$self->{key_modified}{"Total_Count"} = 1; 
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