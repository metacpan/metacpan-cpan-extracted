require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package users::TabTheme;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		font_color => undef,
		background => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_font_color
{
	my ($self) = shift;
	return $self->{font_color}; 
}

sub set_font_color
{
	my ($self,$font_color) = @_;
	$self->{font_color} = $font_color; 
	$self->{key_modified}{"font_color"} = 1; 
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