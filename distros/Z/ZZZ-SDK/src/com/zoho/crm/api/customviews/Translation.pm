require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package customviews::Translation;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		public_views => undef,
		other_users_views => undef,
		shared_with_me => undef,
		created_by_me => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_public_views
{
	my ($self) = shift;
	return $self->{public_views}; 
}

sub set_public_views
{
	my ($self,$public_views) = @_;
	$self->{public_views} = $public_views; 
	$self->{key_modified}{"public_views"} = 1; 
}

sub get_other_users_views
{
	my ($self) = shift;
	return $self->{other_users_views}; 
}

sub set_other_users_views
{
	my ($self,$other_users_views) = @_;
	$self->{other_users_views} = $other_users_views; 
	$self->{key_modified}{"other_users_views"} = 1; 
}

sub get_shared_with_me
{
	my ($self) = shift;
	return $self->{shared_with_me}; 
}

sub set_shared_with_me
{
	my ($self,$shared_with_me) = @_;
	$self->{shared_with_me} = $shared_with_me; 
	$self->{key_modified}{"shared_with_me"} = 1; 
}

sub get_created_by_me
{
	my ($self) = shift;
	return $self->{created_by_me}; 
}

sub set_created_by_me
{
	my ($self,$created_by_me) = @_;
	$self->{created_by_me} = $created_by_me; 
	$self->{key_modified}{"created_by_me"} = 1; 
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