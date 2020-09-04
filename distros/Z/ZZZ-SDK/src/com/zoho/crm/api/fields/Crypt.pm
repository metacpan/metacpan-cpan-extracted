require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package fields::Crypt;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		mode => undef,
		column => undef,
		encfldids => undef,
		notify => undef,
		table => undef,
		status => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_mode
{
	my ($self) = shift;
	return $self->{mode}; 
}

sub set_mode
{
	my ($self,$mode) = @_;
	$self->{mode} = $mode; 
	$self->{key_modified}{"mode"} = 1; 
}

sub get_column
{
	my ($self) = shift;
	return $self->{column}; 
}

sub set_column
{
	my ($self,$column) = @_;
	$self->{column} = $column; 
	$self->{key_modified}{"column"} = 1; 
}

sub get_encfldids
{
	my ($self) = shift;
	return $self->{encfldids}; 
}

sub set_encfldids
{
	my ($self,$encfldids) = @_;
	if(!(ref($encfldids) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: encfldids EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{encfldids} = $encfldids; 
	$self->{key_modified}{"encFldIds"} = 1; 
}

sub get_notify
{
	my ($self) = shift;
	return $self->{notify}; 
}

sub set_notify
{
	my ($self,$notify) = @_;
	$self->{notify} = $notify; 
	$self->{key_modified}{"notify"} = 1; 
}

sub get_table
{
	my ($self) = shift;
	return $self->{table}; 
}

sub set_table
{
	my ($self,$table) = @_;
	$self->{table} = $table; 
	$self->{key_modified}{"table"} = 1; 
}

sub get_status
{
	my ($self) = shift;
	return $self->{status}; 
}

sub set_status
{
	my ($self,$status) = @_;
	$self->{status} = $status; 
	$self->{key_modified}{"status"} = 1; 
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