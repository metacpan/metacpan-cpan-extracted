require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package users::Theme;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		normal_tab => undef,
		selected_tab => undef,
		new_background => undef,
		background => undef,
		screen => undef,
		type => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_normal_tab
{
	my ($self) = shift;
	return $self->{normal_tab}; 
}

sub set_normal_tab
{
	my ($self,$normal_tab) = @_;
	if(!(($normal_tab)->isa("users::TabTheme")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: normal_tab EXPECTED TYPE: users::TabTheme", undef, undef); 
	}
	$self->{normal_tab} = $normal_tab; 
	$self->{key_modified}{"normal_tab"} = 1; 
}

sub get_selected_tab
{
	my ($self) = shift;
	return $self->{selected_tab}; 
}

sub set_selected_tab
{
	my ($self,$selected_tab) = @_;
	if(!(($selected_tab)->isa("users::TabTheme")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: selected_tab EXPECTED TYPE: users::TabTheme", undef, undef); 
	}
	$self->{selected_tab} = $selected_tab; 
	$self->{key_modified}{"selected_tab"} = 1; 
}

sub get_new_background
{
	my ($self) = shift;
	return $self->{new_background}; 
}

sub set_new_background
{
	my ($self,$new_background) = @_;
	$self->{new_background} = $new_background; 
	$self->{key_modified}{"new_background"} = 1; 
}

sub get_background
{
	my ($self) = shift;
	return $self->{background}; 
}

sub set_background
{
	my ($self,$background) = @_;
	$self->{background} = $background; 
	$self->{key_modified}{"background"} = 1; 
}

sub get_screen
{
	my ($self) = shift;
	return $self->{screen}; 
}

sub set_screen
{
	my ($self,$screen) = @_;
	$self->{screen} = $screen; 
	$self->{key_modified}{"screen"} = 1; 
}

sub get_type
{
	my ($self) = shift;
	return $self->{type}; 
}

sub set_type
{
	my ($self,$type) = @_;
	$self->{type} = $type; 
	$self->{key_modified}{"type"} = 1; 
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