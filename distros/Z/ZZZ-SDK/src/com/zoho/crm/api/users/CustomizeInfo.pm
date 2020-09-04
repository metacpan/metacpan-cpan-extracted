require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package users::CustomizeInfo;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		notes_desc => undef,
		show_right_panel => undef,
		bc_view => undef,
		show_home => undef,
		show_detail_view => undef,
		unpin_recent_item => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_notes_desc
{
	my ($self) = shift;
	return $self->{notes_desc}; 
}

sub set_notes_desc
{
	my ($self,$notes_desc) = @_;
	$self->{notes_desc} = $notes_desc; 
	$self->{key_modified}{"notes_desc"} = 1; 
}

sub get_show_right_panel
{
	my ($self) = shift;
	return $self->{show_right_panel}; 
}

sub set_show_right_panel
{
	my ($self,$show_right_panel) = @_;
	$self->{show_right_panel} = $show_right_panel; 
	$self->{key_modified}{"show_right_panel"} = 1; 
}

sub get_bc_view
{
	my ($self) = shift;
	return $self->{bc_view}; 
}

sub set_bc_view
{
	my ($self,$bc_view) = @_;
	$self->{bc_view} = $bc_view; 
	$self->{key_modified}{"bc_view"} = 1; 
}

sub get_show_home
{
	my ($self) = shift;
	return $self->{show_home}; 
}

sub set_show_home
{
	my ($self,$show_home) = @_;
	$self->{show_home} = $show_home; 
	$self->{key_modified}{"show_home"} = 1; 
}

sub get_show_detail_view
{
	my ($self) = shift;
	return $self->{show_detail_view}; 
}

sub set_show_detail_view
{
	my ($self,$show_detail_view) = @_;
	$self->{show_detail_view} = $show_detail_view; 
	$self->{key_modified}{"show_detail_view"} = 1; 
}

sub get_unpin_recent_item
{
	my ($self) = shift;
	return $self->{unpin_recent_item}; 
}

sub set_unpin_recent_item
{
	my ($self,$unpin_recent_item) = @_;
	$self->{unpin_recent_item} = $unpin_recent_item; 
	$self->{key_modified}{"unpin_recent_item"} = 1; 
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