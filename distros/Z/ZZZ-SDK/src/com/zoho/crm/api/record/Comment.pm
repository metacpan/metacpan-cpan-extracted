require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package record::Comment;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		commented_by => undef,
		commented_time => undef,
		comment_content => undef,
		id => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_commented_by
{
	my ($self) = shift;
	return $self->{commented_by}; 
}

sub set_commented_by
{
	my ($self,$commented_by) = @_;
	$self->{commented_by} = $commented_by; 
	$self->{key_modified}{"commented_by"} = 1; 
}

sub get_commented_time
{
	my ($self) = shift;
	return $self->{commented_time}; 
}

sub set_commented_time
{
	my ($self,$commented_time) = @_;
	if(!(($commented_time)->isa("DateTime")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: commented_time EXPECTED TYPE: DateTime", undef, undef); 
	}
	$self->{commented_time} = $commented_time; 
	$self->{key_modified}{"commented_time"} = 1; 
}

sub get_comment_content
{
	my ($self) = shift;
	return $self->{comment_content}; 
}

sub set_comment_content
{
	my ($self,$comment_content) = @_;
	$self->{comment_content} = $comment_content; 
	$self->{key_modified}{"comment_content"} = 1; 
}

sub get_id
{
	my ($self) = shift;
	return $self->{id}; 
}

sub set_id
{
	my ($self,$id) = @_;
	$self->{id} = $id; 
	$self->{key_modified}{"id"} = 1; 
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