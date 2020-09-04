require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package tags::ConflictWrapper;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		conflict_id => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_conflict_id
{
	my ($self) = shift;
	return $self->{conflict_id}; 
}

sub set_conflict_id
{
	my ($self,$conflict_id) = @_;
	$self->{conflict_id} = $conflict_id; 
	$self->{key_modified}{"conflict_id"} = 1; 
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