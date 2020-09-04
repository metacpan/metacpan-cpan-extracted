require 'src/com/zoho/crm/api/util/Choice.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package bulkwrite::File;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		status => undef,
		name => undef,
		added_count => undef,
		skipped_count => undef,
		updated_count => undef,
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
	$self->{key_modified}{"status"} = 1; 
}

sub get_name
{
	my ($self) = shift;
	return $self->{name}; 
}

sub set_name
{
	my ($self,$name) = @_;
	$self->{name} = $name; 
	$self->{key_modified}{"name"} = 1; 
}

sub get_added_count
{
	my ($self) = shift;
	return $self->{added_count}; 
}

sub set_added_count
{
	my ($self,$added_count) = @_;
	$self->{added_count} = $added_count; 
	$self->{key_modified}{"added_count"} = 1; 
}

sub get_skipped_count
{
	my ($self) = shift;
	return $self->{skipped_count}; 
}

sub set_skipped_count
{
	my ($self,$skipped_count) = @_;
	$self->{skipped_count} = $skipped_count; 
	$self->{key_modified}{"skipped_count"} = 1; 
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
	$self->{key_modified}{"updated_count"} = 1; 
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
	$self->{key_modified}{"total_count"} = 1; 
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