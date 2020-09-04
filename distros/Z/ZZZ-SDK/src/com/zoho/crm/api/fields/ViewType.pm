require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package fields::ViewType;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		view => undef,
		edit => undef,
		create => undef,
		quick_create => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_view
{
	my ($self) = shift;
	return $self->{view}; 
}

sub set_view
{
	my ($self,$view) = @_;
	$self->{view} = $view; 
	$self->{key_modified}{"view"} = 1; 
}

sub get_edit
{
	my ($self) = shift;
	return $self->{edit}; 
}

sub set_edit
{
	my ($self,$edit) = @_;
	$self->{edit} = $edit; 
	$self->{key_modified}{"edit"} = 1; 
}

sub get_create
{
	my ($self) = shift;
	return $self->{create}; 
}

sub set_create
{
	my ($self,$create) = @_;
	$self->{create} = $create; 
	$self->{key_modified}{"create"} = 1; 
}

sub get_quick_create
{
	my ($self) = shift;
	return $self->{quick_create}; 
}

sub set_quick_create
{
	my ($self,$quick_create) = @_;
	$self->{quick_create} = $quick_create; 
	$self->{key_modified}{"quick_create"} = 1; 
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