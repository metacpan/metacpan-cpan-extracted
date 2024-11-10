package Tk::AppWindow::Ext::Art;

=head1 NAME

Tk::AppWindow::Ext::Art - Use icon libraries quick & easy

=cut


use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.16";
use Config;
my $mswin = 0;
$mswin = 1 if $Config{'osname'} eq 'MSWin32';
my $osname = $Config{'osname'};

use base qw( Tk::AppWindow::BaseClasses::Extension );

use File::Basename;
use File::MimeInfo;
use Imager;
use MIME::Base64;
require FreeDesktop::Icons;
require Tk::Compound;
require Tk::Photo;
use Tk::PNG;

my $svgsupport = 0;
eval 'use Image::LibRSVG';
$svgsupport = 1 unless $@;

my $t;
eval '$t = `fc-list :family=xxxx:style=yyyy`';
my $fc_list_supported = defined $t;

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
	$self->{CACHE} = {};
	$self->{CACHEDISABLED} = 0;
	$self->{FDI} = $fdi;
	$self->{THEMEPOOL} = {};
	$self->{THEMES} = {};
	$self->{ICONSIZE} = undef;

	$self->cmdConfig(
		available_icon_sizes => ['AvailableSizesCurrentTheme', $self],
		available_icon_themes => ['AvailableThemes', $self],
	);

	$self->addPreConfig(
		-compoundcolspace =>['PASSIVE', undef, undef, 3],
		-iconsize => ['PASSIVE', 'iconSize', 'IconSize', 16],
		-icontheme => ['PASSIVE', 'iconTheme', 'IconTheme', 'Oxygen'],
	);
	
	$self->configInit(
		-rawiconpath => ['rawpath', $fdi],
	);

	$self->addPostConfig('DoPostConfig', $self);
	
	return $self;
}

sub _cache {
	my $self = shift;
	$self->{CACHE} = shift if @_;
	return $self->{CACHE}
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

sub cacheAdd {
	my ($self, $name, $image) = @_;
	my $cache = $self->_cache;
	unless ($self->cacheExists($name)) {
		$cache->{$name} = $image;
	} else {
		warn "Art::cache '$name' already exists"
	}
}

=item B<cacheDisabled>I<(?$flag?)>

Sets and returns the state of the cache.
If the cache is disabled, images will allways be loaded from disk.

=cut

sub cacheDisabled {
	my $self = shift;
	$self->{CACHEDISABLED} = shift if @_;
	return $self->{CACHEDISABLED}
}


sub cacheExists {
	my ($self, $name) = @_;
	my $cache = $self->_cache;
	return exists $cache->{$name}
}

=item B<cacheClear>

Clears the cache.

=cut

sub cacheClear {
	my $self = shift;
	$self->_cache({})
}

sub cacheGet {
	my ($self, $name) = @_;
	my $cache = $self->_cache;
	return $cache->{$name} if $self->cacheExists($name);
	warn "Art::cache '$name' does not exist"
}

sub cacheName {
	my ($self, $file, $width, $height) = @_;
	$width = '' unless defined $width;
	$height = $width unless defined $height;
	return "$file-$width-$height"
}

=item B<canRotateText>

Returns true if facilities for rotating text are in place.
On linux this means the command 'fc-list' works.

=cut

sub canRotateText {
	my $self = shift;
	return 1 if $mswin;
	return $fc_list_supported;
}

=item B<createCompound>I<(%args)>

Creates and returns a compound image.
%args can have the following keys;

B<-image> Reference to a Tk::Image object.

B<-textrotate> An angle in degrees.

B<-text> Text to be displayed.

B<textside> Can be 'left', 'right', 'top' or 'bottom'. Default is 'right'.

=cut

sub createCompound {
	my $self = shift;
	my %args = (@_);
	
	my $side = delete $args{'-textside'};
	my $text = delete $args{'-text'};
	my $image = delete $args{'-image'};
	my $rotate = delete $args{'-textrotate'};
	my $textimage;
	$textimage = $self->text2image($text, $rotate) if defined $rotate;
	$side = 'right' unless defined $side;
	my $compound = $self->Compound;
	if ($side eq 'left') {
		if (defined $textimage) {
			$compound->Image(-image => $textimage);
		} else {
			$compound->Text(-text => $text, -anchor => 'c') if defined $text;
		}
		if (defined $image) {
			$compound->Space(-width => $self->configGet('-compoundcolspace'));
			$compound->Image(-image => $image);
		}
	} elsif ($side eq 'right') {
		$compound->Image(-image => $image) if defined $image;
		if (defined $textimage) {
			$compound->Space(-width => $self->configGet('-compoundcolspace'));
			$compound->Image(-image => $textimage);
		} elsif (defined $text) {
			$compound->Space(-width => $self->configGet('-compoundcolspace'));
			$compound->Text(-text => $text, -anchor => 'c');
		}
	} elsif ($side eq 'top') {
		if (defined $textimage) {
			$compound->Image(-image => $textimage);
		} else {
			$compound->Text(-text => $text, -anchor => 'c') if defined $text;
		}
		if (defined $image) {
			$compound->Line(-pady => $self->configGet('-compoundcolspace'));
			$compound->Image(-image => $image);
		}
	} elsif ($side eq 'bottom') {
		$compound->Image(-image => $image) if defined $image;
		if (defined $textimage) {
			$compound->Line(-pady => $self->configGet('-compoundcolspace'));
			$compound->Image(-image => $textimage);
		} elsif (defined $text) {
			$compound->Line(-pady => $self->configGet('-compoundcolspace'));
			$compound->Text(-text => $text, -anchor => 'c');
		}
	} elsif ($side eq 'none') {
		$compound->Image(-image => $image) if defined $image;
	} else {
		warn "illegal value $side for -textside. Should be 'left', 'right' 'top', bottom' or 'none'"
	}
	return $compound;
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

sub fontFile {
	my ($self, $font) = @_;
	my $family = $self->fontActual($font, '-family');
	$family =~ s/\s//g; #remove spaces
	my $slant = $self->fontActual($font, '-slant');
	my $weight = $self->fontActual($font, '-weight');
	$slant = '' if $slant eq 'roman';
	$weight = '' if $weight eq 'normal';
	my $style = $weight . $slant;
	if ($style eq '') {
		for ('regular', 'normal', 'roman') {
			my $f = $self->fontFind($family, $_);
			if (defined $f) {
				last
				return $f
			}
		}
	} else {
		return $self->fontFind($family, $style);
	}
}

sub fontFind {
	my ($self, $family, $style) = @_;
	my $res = `fc-list :family=$family:style=$style`;
	if ($res =~ s/([^\:]*)\:.*\n//) {
		return $1
	}
	return undef
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


=item B<getFileIcon>I<($file>, [ I<$size, $context> ] I<);>

Determines the mime type of $file and returns the belonging
icon. If it can not determine the mime type, the default file 
icon is returned.

=cut

sub getFileIcon {
	my $self = shift;
	my $file = shift;
	my $mime = mimetype($file);
	if (defined $mime) {
		$mime =~ s/\//-/;
		my $icon = $self->getIcon($mime, @_);
		return $icon if defined $icon
	}
	return $self->getIcon('text-plain', @_)
}

=item B<getIcon>I<($name>, [ I<$size, $context> ] I<);>

Returns a Tk::Photo object. If you do not specify I<$size> or the icon does
not exist in the specified size, it will find the largest possible icon and
scale it to the requested size. I<$force> can be 0 or 1. It is 0 by default.
If you set it to 1 a missing icon image is returned instead of undef when the
icon cannot be found.

=cut

sub getIcon {
	my ($self, $name, $size, $context) = @_;
	$size = $self->configGet('-iconsize') unless defined $size;
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

	my $load = 0;

	#create chache name
	my $cachename = $self->cacheName($file, $width, $height);

	if ($self->cacheExists($cachename)) {
		return $self->cacheGet($cachename) unless $self->cacheDisabled;
	}
	if (-e $file) {
		my $data;
		unless ($self->isSVG($file)) {
			my $img = Imager->new(file=>$file);
			if (defined $img) {
				$width = $img->getwidth unless defined $width;
				$height = $img->getheight unless defined $height;
				if (($width ne $img->getwidth) or ($height ne $img->getheight)) {
					$img = $img->scale(xpixels => $width, ypixels => $height)
				}
				$img->write(data => \$data, type => 'png');
			}
		} else {
			unless ($svgsupport) {
				warn "Svg images not supported on this system";
				return undef;
			}
			my $renderer = Image::LibRSVG->new;
			$renderer->loadFromFileAtSize($file, $width, $height);
			$data = $renderer->getImageBitmap("png", 100);
		}
		if (defined $data) {
			my $i = $self->GetAppWindow->Photo(
				-data => encode_base64($data), 
				-format => 'png',
			);
			$self->cacheAdd($cachename, $i) unless $self->cacheDisabled;
			return $i
		}
	}  else {
		warn "image file $file not found \n";
	}
	return undef
}


=item B<text2image>I<($text, ?$rotate?)>

Returns a Tk::Photo class with $text as image. $rotate specifies
how much the text must be rotated in degrees. On linux this only works
if the command 'fc-list' is available.

=cut

sub text2image {
	my ($self, $text, $rotate) = @_;
	return undef unless $fc_list_supported;
	my $l = $self->Label;
	my $fnt = $l->cget('-font');
	my $color = $l->cget('-foreground');
	$color = '#000000' if $color eq 'SystemButtonText';
	my $fontsize = abs($self->fontActual($fnt, '-size'));
	my $width = $self->fontMeasure($fnt, $text) + 2;
	my $height = $self->fontMetrics($fnt, '-linespace') + 2;
	my $desc = $self->fontMetrics($fnt, '-descent');
	my $ypos = $height - $desc - 1;
	$l->destroy;
	
	my $img = Imager->new(xsize => $width, ysize => $height, channels => 4);
	
	$color = Imager::Color->new($color) or die "Color";

	my $font;	
	if ($mswin) {
		my $fontdesc = $self->fontActual($fnt, '-family');
		my $fontweight = $l->fontActual($fnt, '-weight');
		$fontdesc = "$fontdesc bold" if $fontweight eq 'bold';
		my $fontslant = $l->fontActual($fnt, '-slant');
		$fontdesc = "$fontdesc italic" if $fontslant eq 'italic';
		$font = Imager::Font->new(
			face  => $fontdesc,
			size  => $fontsize,
		) or die Imager->errstr;
	} else {
		my $fontfile = $self->fontFile($fnt);
		$font = Imager::Font->new(
			file  => $fontfile,
			size  => $fontsize,
		) or die Imager->errstr;
	}
	
	$img->string(
		x => 1,
		'y' => $ypos,
		font => $font, 
		string => $text, 
		color => $color, 
		aa => 1,
	) or die "String";

	if (defined $rotate) {
		my $new = $img->rotate(degrees => $rotate);
		$img = $new;
	}
	
	my $data;
	$img->write(data => \$data, type => 'png');
	return $self->Photo(
		-format => 'png',
		-data => encode_base64($data)
	)
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






