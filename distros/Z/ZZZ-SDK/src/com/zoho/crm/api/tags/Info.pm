require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package tags::Info;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		count => undef,
		allowed_count => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_count
{
	my ($self) = shift;
	return $self->{count}; 
}

sub set_count
{
	my ($self,$count) = @_;
	$self->{count} = $count; 
	$self->{key_modified}{"count"} = 1; 
}

sub get_allowed_count
{
	my ($self) = shift;
	return $self->{allowed_count}; 
}

sub set_allowed_count
{
	my ($self,$allowed_count) = @_;
	$self->{allowed_count} = $allowed_count; 
	$self->{key_modified}{"allowed_count"} = 1; 
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