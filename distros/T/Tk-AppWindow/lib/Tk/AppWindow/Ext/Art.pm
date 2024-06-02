package Tk::AppWindow::Ext::Art;

=head1 NAME

Tk::AppWindow::Ext::Art - Use icon libraries quick & easy

=cut


use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.05";
use Config;
my $mswin = 0;
$mswin = 1 if $Config{'osname'} eq 'MSWin32';
my $osname = $Config{'osname'};

use base qw( Tk::AppWindow::BaseClasses::Extension );

use Module::Load::Conditional('check_install', 'can_load');
$Module::Load::Conditional::VERBOSE = 1;

use File::Basename;
use Imager;
use MIME::Base64;
require FreeDesktop::Icons;
require Tk::Compound;
require Tk::Photo;
use Tk::PNG;

my $svgsupport = 0;

my $modname = 'Image::LibRSVG';
my $inst = check_install(module => $modname);
if (defined $inst) {
	if (can_load(modules => {$modname => $inst->{'version'}})){
		$svgsupport = 1;
	}
}

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['Art'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

This extension allows B<Tk::AppWindow> easy access to icon libraries used in desktops
like KDE and GNOME.

if you are not on Windows, it supports libraries containing scalable vector graphics like Breeze.

On Windows you have to install icon libraries yourself in C:\ProgramData\Icons.
You will find plenty of them on Github. Extract an icon set and copy the main
folder of the theme (the one that contains the file 'index.theme') to
C:\ProgramData\Icons. On Linux you will probably find some icon themes
in /usr/share/icons.

The constructor takes a reference to a list of folders where it finds the icons
libraries. If you specify nothing, it will assign default values for:

Windows:  $ENV{ALLUSERSPROFILE} . '\Icons'. Art will not create 
the folder if it does not exist.

Others: $ENV{HOME} . '/.local/share/icons', '/usr/share/icons'

=head1 CONFIG VARIABLES

=over 4

=item Switch: B<-compoundcolspace>

Default value 5. Used in the B<createCompound> method to
set horizontal spacing.

=item Switch: B<-iconpath>

Specify a list of folders where your icon libraries are located.
Only available at create time.

=item Name  : B<iconSize>

=item Class : B<IconSize>

=item Switch: B<-iconsize>

Default is 16.

=item Name  : B<iconTheme>

=item Class : B<IconTheme>

=item Switch: B<-icontheme>

Default is Oxygen.

=item Switch: B<-rawiconpath>

List of folders where you store your raw icons. Defaults to an empty list.

=back

=head1 COMMANDS

The following commands are defined.

=over 4

=item B<available_icon_sizes>

Returns a list of available icon sizes.

=item B<available_icon_themes>

Returns a list of available icon themes.

=back

=head1 METHODS

=over 4

=cut


sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	my $args = $self->GetArgsRef;

	my $ip = delete $args->{'-iconpath'};
	$ip = [] unless defined $ip;

	my $fdi = FreeDesktop::Icons->new(@$ip);
	$self->{FDI} = $fdi;
	$self->{THEMEPOOL} = {};
	$self->{THEMES} = {};
	$self->{ICONSIZE} = undef;

	$self->cmdConfig(
		available_icon_sizes => ['AvailableSizesCurrentTheme', $self],
		available_icon_themes => ['AvailableThemes', $self],
	);

	$self->addPreConfig(
		-compoundcolspace =>['PASSIVE', undef, undef, 5],
		-iconsize => ['PASSIVE', 'iconSize', 'IconSize', 16],
		-icontheme => ['PASSIVE', 'iconTheme', 'IconTheme', 'Oxygen'],
	);
	
	$self->configInit(
		-rawiconpath => ['rawpath', $fdi],
	);

	$self->addPostConfig('DoPostConfig', $self);
	
	return $self;
}

sub _fdi {
	return $_[0]->{FDI}
}

sub AvailableContexts {
	my $self = shift;
	return $self->_fdi->availableContexts(@_);
}

sub AvailableIcons {
	my $self = shift;
	return $self->_fdi->availableIcons(@_);
}

sub AvailableSizes {
	my $self = shift;
	return $self->_fdi->availableSizes(@_);
}

sub AvailableSizesCurrentTheme {
	my $self = shift;
	return $self->AvailableSizes($self->configGet('-icontheme'));
}


sub AvailableThemes {
	my $self = shift;
	my $fdi = $self->_fdi;
	return $fdi->availableThemes
}

=item B<createCompound>I<(%args)>

Creates and returns a compound image.
%args can have the following keys;

B<-image> Reference to a Tk::Image object.

B<-orient> Either 'Horizontal' or 'Vertical'. Default is 'Horizontal'.

B<-text> Text to be displayed.

B<textside> Can be 'left', 'right', 'top' or 'bottom'. Default is 'right'.

=cut

sub createCompound {
	my $self = shift;
	my %args = (@_);
	
	my $side = delete $args{'-textside'};
	my $orient = delete $args{'-orient'};
	$orient = 'Horizontal' unless defined $orient;
	my $text = delete $args{'-text'};
	my $image = delete $args{'-image'};
	$side = 'right' unless defined $side;
	my $compound = $self->Compound;
	if ($side eq 'left') {
		if ($orient eq 'Vertical') {
			$self->CreateCompoundVertical($compound, $text);
		} else {
			$compound->Text(-text => $text, -anchor => 'c');
		}
		$compound->Space(-width => $self->configGet('-compoundcolspace'));
		$compound->Image(-image => $image);
	} elsif ($side eq 'right') {
		$compound->Image(-image => $image);
		$compound->Space(-width => $self->configGet('-compoundcolspace'));
		if ($orient eq 'Vertical') {
			$self->CreateCompoundVertical($compound, $text);
		} else {
			$compound->Text(-text => $text, -anchor => 'c');
		}
	} elsif ($side eq 'top') {
		if ($orient eq 'Vertical') {
			$self->CreateCompoundVertical($compound, $text);
		} else {
			$compound->Text(-text => $text, -anchor => 'c');
		}
		$compound->Line;
		$compound->Image(-image => $image);
	} elsif ($side eq 'bottom') {
		$compound->Image(-image => $image);
		$compound->Line;
		if ($orient eq 'Vertical') {
			$self->CreateCompoundVertical($compound, $text);
		} else {
			$compound->Text(-text => $text, -anchor => 'c');
		}
	} elsif ($side eq 'none') {
		$compound->Image(-image => $image);
	} else {
		warn "illegal value $side for -textside. Should be 'left', 'right' 'top', bottom' or 'none'"
	}
	return $compound;
}

sub CreateCompoundVertical {
	my ($self, $compound, $text) = @_;
	my @t = split(//, $text);
	for (@t) {
		$compound->Text(-text => $_, -anchor => 'c');
		$compound->Line;
	}
}

=item B<createEmptyImage>I<(?$width?, ?$height?)>

Creates and returns aan empty image. Nothing to see, just taking up space.
If $width is not specified it defaults to the B<-iconsize> config variable.
If $height is not specified it defaults to $width.

=cut

sub createEmptyImage {
	my ($self, $width, $height) = @_;
	$width = $self->configGet('-iconsize') unless defined $width;
	$height = $width unless defined $height;
	my $empty = '/* XPM */
static char * new_xpm[] = {
"' . "$width $height" . ' 3 1",
" 	c None",
".	c #000000",
"+	c #FFFFFF",
';

	my $line = '';
	for (1 ..$width) { $line = "$line " }
	$line = "\"$line\"\n";
	for (1 .. $height) {
		$empty = $empty . $line
	}
	return $self->Pixmap(-data => $empty);
}

sub DoPostConfig {
	my $self = shift;
	
	#Fixing name problem. Gtk init files specify the used icon library
	#as their folder name instead of the name in their index.
	my $theme = $self->configGet('-icontheme');
	my $fdi = $self->_fdi;
	unless ($fdi->themeExists($theme)) {
		for ($fdi->availableThemes) {
			my $test = $_;
			my $path = $fdi->getPath($test);
			if ($path =~ /$theme$/) {
				$self->configPut(-icontheme => $test);
				last;
			}
		}
	}
	#Fixing cases of specified iconsize not matching any of the
	#available iconsizes.
	my $size = $self->configGet('-iconsize');
	$size = $self->getAlternateSize($size);
	$self->configPut(-iconsize => $size);
}

=item B<getAlternateSize>I<($size>)>

Tests if $size is available in the current itecontheme. Returns 
the first size that is larger than $size if it is not.

=cut

sub getAlternateSize {
	my ($self,$size) = @_;
	my $theme = $self->configGet('-icontheme');
	my $fdi = $self->_fdi;
	my @sizes = $fdi->availableSizes($theme);
	my ($index) = grep { $sizes[$_] eq $size } 0..$#sizes;
	unless (defined $index) {
		for (@sizes) {
			if ($size < $_) {
				$size = $_;
				last;
			}
		}
	}
	return $size
}

=item B<getIcon>I<($name>, [ I<$size, $context> ] I<);>

Returns a Tk::Image. If you do not specify I<$size> or the icon does
not exist in the specified size, it will find the largest possible icon and
scale it to the requested size. I<$force> can be 0 or 1. It is 0 by default.
If you set it to 1 a missing icon image is returned instead of undef when the
icon cannot be found.

=cut

sub getIcon {
	my ($self, $name, $size, $context) = @_;
	unless (defined $size) { $size = $self->configGet('-iconsize')}
	my $fdi = $self->_fdi;
	$fdi->theme($self->configGet('-icontheme'));
	my $resize = 0;
	my $file = $fdi->get($name, $size, $context, \$resize);
	if (defined $file) { 
		return $self->loadImage($file, $size);
	}
	return undef
}

sub isSVG {
	my ($self, $file) = @_;
	return $file =~ /\.svg$/i
}

=item B<loadImage>I<($file, ?$width?, ?$height?)>

Loads image I<$file> and returns it as a Tk::Photo object. It will
resize the image to I<$width> and I<$height> if they are specified.
if only I<$width> is specified height is set equal to width.

=cut

sub loadImage {
	my ($self, $file, $width, $height) = @_;
	if (defined $width) {
		$height = $width unless defined $height
	}
	if (-e $file) {
		unless ($self->isSVG($file)) {
			my $img = Imager->new(file=>$file);
			if (defined $img) {
				$width = $img->getwidth unless defined $width;
				$height = $img->getheight unless defined $height;
				$img = $img->scale(xpixels => $width, ypixels => $height) if ($width ne $img->getwidth) or ($height ne $img->getheight);;
				my $data;
				$img->write(data => \$data, type => 'png');
				return $self->GetAppWindow->Photo(
					-data => encode_base64($data), 
					-format => 'png',
				)
			}
		} else {
			unless ($svgsupport) {
				warn "Svg images not supported on this system";
				return undef;
			}
			my $renderer = Image::LibRSVG->new;
			$renderer->loadFromFileAtSize($file, $width, $height);
			my $png = $renderer->getImageBitmap("png", 100);
			if (defined $png) {
				return $self->GetAppWindow->Photo(
					-data => encode_base64($png), 
					-format => 'png'
				);
			} 
		}
	}  else {
		warn "image file $file not found \n";
	}
	return undef
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::AppWindow>

=item L<Tk::AppWindow::BaseClasses::Extension>

=back

=cut

1;






