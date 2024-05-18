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
require Tk::Compound;
require Tk::Photo;
use Tk::PNG;
use Tk::JPEG;

my @extensions = (
	'.jpg',
	'.jpeg',
	'.png',
	'.gif',
	'.xbm',
	'.xpm',
);

my %photoext = (
	'.jpg' => ['Photo', -format => 'jpeg'],
	'.jpeg' => ['Photo', -format => 'jpeg'],
	'.png' => ['Photo', -format => 'png'],
);

my @defaulticonpath = ();
if ($mswin) {
	push @defaulticonpath, $ENV{ALLUSERSPROFILE} . '\Icons'
} else {
	my $modname = 'Image::LibRSVG';
	my $inst = check_install(module => $modname);
	if (defined $inst) {
		if (can_load(modules => {$modname => $inst->{'version'}})){
			push @extensions, '.svg';
		}
	}
	my $local = $ENV{HOME} . '/.local/share/icons';
	push @defaulticonpath,  $local if -e $local;
	my $xdgpath = $ENV{XDG_DATA_DIRS};
	if (defined $xdgpath) {
		my @xdgdirs = split /\:/, $xdgpath;
		for (@xdgdirs) {
			push @defaulticonpath, "$_/icons";
		}
	}
}

my @iconpath = ();

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

Default value 5. Used in the B<CreateCompound> method to
set horizontal spacing.

=item Switch: B<-iconpath>

For defaults see above.
Only available at create time.

=item Switch: B<-iconsize>

Default is 16.

=item Name  : B<iconTheme>

=item Class : B<IconTheme>

=item Switch: B<-icontheme>

Default is Oxygen.

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

	my $ip = delete $args->{'-iconpath'};
	if (defined $ip) { 
		@iconpath = @$ip 
	} else {
		@iconpath = @defaulticonpath
	}
	$self->CollectThemes(@iconpath);

	$self->addPostConfig('DoPostConfig', $self);
	
	return $self;
}


=item B<AvailableContexts>I<($theme, >[ I<$name, $size> ] I<);>

Returns a list of available contexts. If you set $name to undef if will return
all contexts of size $size. If you set $size to undef it will return all
contexts associated with icon $name. If you set $name and $size to undef it
will return all known contexts in the theme. out $size it returns a list
of all contexts found in $theme.

=cut

sub AvailableContexts {
	my ($self, $theme, $name, $size) = @_;
	my $t = $self->GetTheme($theme);
	my %found = ();
	if ((not defined $name) and (not defined $size)) {
		my @names = keys %$t;
		for (@names) {
			my $si = $t->{$_};
			my @sizes = keys %$si;
			for (@sizes) {
				my $ci = $si->{$_};
				for (keys %$ci) {
					$found{$_} = 1;
				}
			}
		}
	} elsif ((defined $name) and (not defined $size)) {
		if (exists $t->{$name}) {
			my $si = $t->{$name};
			my @sizes = keys %$si;
			for (@sizes) {
				my $ci = $si->{$_};
				for (keys %$ci) {
					$found{$_} = 1;
				}
			}
		}
	} elsif ((not defined $name) and (defined $size)) {
		my @names = keys %$t;
		for (@names) {
			if (exists $t->{$_}->{$size}) {
				my $ci = $t->{$_}->{$size};
				for (keys %$ci) {
					$found{$_} = 1;
				}
			}
		}
	} else {
		if (exists $t->{$name}) {
			my $si = $t->{$name};
			if (exists $si->{$size}) {
				my $ci = $si->{$size};
				%found = %$ci;
			}
		}
	}
	my $parent = $self->ParentTheme($theme);
	if (defined $parent) {
		my @contexts = $self->AvailableContexts($parent, $name, $size);
		for (@contexts) {
			$found{$_} = 1
		}
	}
	return sort keys %found
}

=item B<AvailableIcons>I<($theme, >[ I<$size, $context> ] I<);>

Returns a list of available icons. If you set $size to undef the list will 
contain names it found in all sizes. If you set $context to undef it will return
names it found in all contexts. If you leave out both then
you get a list of all available icons. Watch out, it might be pretty long.

=cut

sub AvailableIcons {
	my ($self, $theme, $size, $context) = @_;
	my $t = $self->GetTheme($theme);

	my @names = keys %$t;
	my %matches = ();
	if ((not defined $size) and (not defined $context)) {
		%matches = %$t
	} elsif ((defined $size) and (not defined $context)) {
		for (@names) {
			if (exists $t->{$_}->{$size}) { $matches{$_} = 1 }
		}
	} elsif ((not defined $size) and (defined $context)) {
		for (@names) {
			my $name = $_;
			my $si = $t->{$name};
			my @sizes = keys %$si;
			for (@sizes) {
				if (exists $t->{$name}->{$_}->{$context}) { $matches{$name} = 1 }
			}
		}
	} else {
		for (@names) {
			if (exists $t->{$_}->{$size}) {
				my $c = $t->{$_}->{$size};
				if (exists $c->{$context}) {
					 $matches{$_} = 1 
				}
			}
		}
	}
	my $parent = $self->ParentTheme($theme);
	if (defined $parent) {
		my @icons = $self->AvailableIcons($parent, $size, $context);
		for (@icons) {
			 $matches{$_} = 1
		}
	}
	return sort keys %matches
}

=item B<AvailableThemes>

Returns a list of available themes it found while initiating the module.

=cut

sub AvailableThemes {
	my $self = shift;
	my $k = $self->{THEMES};
	return sort keys %$k
}


=item B<AvailableSizes>I<($theme, >[ I<$name, $context> ] I<);>

Returns a list of available contexts. If you leave out $size it returns a list
of all contexts found in $theme.

=cut

sub AvailableSizes {
	my ($self, $theme, $name, $context) = @_;
	my $t = $self->GetTheme($theme);
	return () unless defined $t;

	my %found = ();
	if ((not defined $name) and (not defined $context)) {
		my @names = keys %$t;
		for (@names) {
			my $si = $t->{$_};
			my @sizes = keys %$si;
			for (@sizes) {
				$found{$_} = 1
			}
		}
	} elsif ((defined $name) and (not defined $context)) {
		if (exists $t->{$name}) {
			my $si = $t->{$name};
			%found = %$si;
		}
	} elsif ((not defined $name) and (defined $context)) {
		my @names = keys %$t;
		for (@names) {
			my $n = $_;
			my $si = $t->{$n};
			my @sizes = keys %$si;
			for (@sizes) {
				if (exists $t->{$n}->{$_}->{$context}) {
					$found{$_} = 1
				}
			}
		}
	} else {
		if (exists $t->{$name}) {
			my $si = $t->{$name};
			my @sizes = keys %$si;
			for (@sizes) {
				if (exists $t->{$name}->{$_}->{$context}) {
					$found{$_} = 1
				}
			}
		}
	}
	my $parent = $self->ParentTheme($theme);
	if (defined $parent) {
		my @sizes = $self->AvailableSizes($parent, $name, $context);
		for (@sizes) {
			$found{$_} = 1
		}
	}
	delete $found{'unknown'};
	return sort {$a <=> $b} keys %found
}

sub AvailableSizesCurrentTheme {
	my $self = shift;
	return $self->AvailableSizes($self->configGet('-icontheme'));
}

sub CollectThemes {
	my $self = shift;
	my %themes = ();
	for (@_) {
		my $dir = $_;
		if (opendir DIR, $dir) {
			while (my $entry = readdir(DIR)) {
				my $fullname = "$dir/$entry";
				if (-d $fullname) {
					if (-e "$fullname/index.theme") {
						my $index = $self->LoadThemeFile($fullname);
						my $main = delete $index->{general};
						my $name = $main->{'Name'};
						if (%$index) {
							$themes{$name} = {
								path => $fullname,
								general => $main,
								folders => $index,
							}
						}
					}
				}
			}
			closedir DIR;
		}
	}
	$self->{THEMES} = \%themes
}

=item B<CreateCompound>I<(%args)>

Creates and returns a compound image.
%args can have the following keys;

B<-image> Reference to a Tk::Image object.

B<-orient> Either 'Horizontal' or 'Vertical'. Default is 'Horizontal'.

B<-text> Text to be displayed.

B<textside> Can be 'left', 'right', 'top' or 'bottom'. Default is 'right'.

=cut

sub CreateCompound {
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

=item B<CreateEmptyImage>I<(?$width?, ?$height?)>

Creates and returns aan empty image. Nothing to see, just taking up space.
If $width is not specified it defaults to the B<-iconsize> config variable.
If $height is not specified it defaults to $width.

=cut

sub CreateEmptyImage {
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

sub CreateIndex {
	my ($self, $tindex) = @_;
	my %index = ();
	my $base = $tindex->{path};
	my $folders = $tindex->{folders};
	foreach my $dir (keys %$folders) {
		my @raw = <"$base/$dir/*">;
		foreach my $file (@raw) {
			if ($self->IsImageFile($file)) {
				my ($name, $d, $e) = fileparse($file, @extensions);
				unless (exists $index{$name}) {
					$index{$name} = {}
				}
				my $size = $folders->{$dir}->{Size};
				unless (defined $size) {
					$size = 'unknown';
				}
				unless (exists $index{$name}->{$size}) {
					$index{$name}->{$size} = {}
				}
				my $context = $folders->{$dir}->{Context};
				unless (defined $context) {
					$context = 'unknown';
				}
				$index{$name}->{$size}->{$context} = $file;
			}
		}
	}
	return \%index;
}

sub DoPostConfig {
	my $self = shift;
	
	#Fixing name problem. Gtk init files specify the used icon library
	#as their folder name instead of the name in their index.
	my $theme = $self->configGet('-icontheme');
	unless (exists $self->{THEMES}->{$theme}) {
		for ($self->AvailableThemes) {
			my $test = $self->{THEMES}->{$_};
			my $path = $test->{'path'};
			if ($path =~ /$theme$/) {
				$theme = $_;
				$self->configPut(-icontheme => $theme);
				last;
			}
		}
	}
	#Fixing cases of specified iconsize not matching any of the
	#available iconsizes.
	my $size = $self->configGet('-iconsize');
	$size = $self->GetAlternateSize($size);
	$self->configPut(-iconsize => $size);
}

=item B<FindImage>I<($name, >[ I<$size, $context, \$resize> ] I<);>

Returns the filename of an image in the library. Finds the best suitable
version of the image in the library according to $size and $context. If it
eventually returns an image of another size, it sets $resize to 1. This gives
the opportunity to scale the image to the requested icon size. All parameters
except $name are optional.

=cut

sub FindImage {
	my ($self, $name, $size, $context, $resize) = @_;
	my $img = $self->FindRawImage($name, $size, $resize);
	return $img if defined $img;
	return $self->FindLibImage($name, $size, $context, $resize);
}

sub FindImageC {
	my ($self, $si, $context) = @_;
	if (exists $si->{$context}) {
		return $si->{$context}
	} else {
		my @contexts = sort keys %$si;
		if (@contexts) {
			return $si->{$contexts[0]};
		}
	}
	return undef
}

sub FindImageS {
	my ($self, $nindex, $size, $context, $resize) = @_;
	if (exists $nindex->{$size}) {
		my $file = $self->FindImageC($nindex->{$size}, $context);
		if (defined $file) { return $file }
	} else {
		if (defined $resize) { $$resize = 1 }
		my @sizes = reverse sort keys %$nindex;
		for (@sizes) {
			my $si = $nindex->{$_};
			my $file = $self->FindImageC($si, $context);
			if (defined $file) { return $file }
		}
	}
	return undef
}

=item B<FindLibImage>I<($name, >[ I<$size, $context, \$resize> ] I<);>

Returns the filename of an image in the library. Finds the best suitable
version of the image in the library according to $size and $context. If it
eventually returns an image of another size, it sets $resize to 1. This gives
the opportunity to scale the image to the requested icon size. All parameters
except $name are optional.

=cut

sub FindLibImage {
	my ($self, $name, $size, $context, $resize, $theme) = @_;

	$size = 'unknown' unless (defined $size);
	$context = 'unknown' unless (defined $context);
	$theme = $self->configGet('-icontheme') unless defined $theme;

	my $index = $self->GetTheme($theme);
	return $self->FindImageS($index->{$name}, $size, $context, $resize) if exists $index->{$name};

	my $parent = $self->ParentTheme($theme);
	return $self->FindLibImage($name, $size, $context, $resize, $parent) if defined $parent;

	return undef;
}

=item B<FindRawImage>I<($name, >[ I<$size, $context, \$resize> ] I<);>

Returns the filename of an image in the library. Finds the best suitable
version of the image in the library according to $size and $context. If it
eventually returns an image of another size, it sets $resize to 1. This gives
the opportunity to scale the image to the requested icon size. All parameters
except $name are optional.

=cut

sub FindRawImage {
	my ($self, $name, $size) = @_;
	my $path = $self->{RAWPATH};
	for (@$path) {
		my $folder = $_;
		opendir(DIR, $folder);
		my @files = grep(/!$name\.*/, readdir(DIR));
		closedir(DIR);
		for (@files) {
			my $file = "$folder/$_";
			return $file if $self->IsImage($file);
		}
	}
	return undef
}


=item B<GetAlternateSize>I<($size>)>

Tests if $size is available in the current itecontheme. Returns 
the first size that is larger than $size if it is not.

=cut

sub GetAlternateSize {
	my ($self,$size) = @_;
	my $theme = $self->configGet('-icontheme');
	my @sizes = $self->AvailableSizes($theme);
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

=item B<GetIcon>I<($name>, [ I<$size, $context, $force> ] I<);>

Returns a Tk::Image. If you do not specify I<$size> or the icon does
not exist in the specified size, it will find the largest possible icon and
scale it to the requested size. I<$force> can be 0 or 1. It is 0 by default.
If you set it to 1 a missing icon image is returned instead of undef when the
icon cannot be found.

=cut

sub GetIcon {
	my ($self, $name, $size, $context) = @_;
	unless (defined $size) { $size = $self->configGet('-iconsize')}
	my $file = $self->FindImage($name, $size, $context);
	if (defined $file) { 
		return $self->LoadImage($file, $size);
	}
	return undef
}

=item B<GetTheme>I<($themename)>

Looks for a searchable index of the theme. If it is not yet created it will
be created first and stored in the index pool.

=cut

sub GetTheme {
	my ($self, $name) = @_;
	my $pool = $self->{THEMEPOOL};
	if (exists $pool->{$name}) {
		return $pool->{$name}
	} else {
		my $themindex = $self->{THEMES}->{$name};
		if (defined $themindex) {
			my $index = $self->CreateIndex($themindex);
			$pool->{$name} = $index;
			return $index
		} else {
			return undef
		}
	}
}

=item B<GetThemePath>I<($theme)>

Returns the full path to the folder containing I<$theme>

=cut

sub GetThemePath {
	my ($self, $theme) = @_;
	my $t = $self->{THEMES};
	if (exists $t->{$theme}) {
		return $t->{$theme}->{path}
	} else {
		warn "Icon theme $theme not found"
	}
}

=item B<IsImageFile>I<($file)>

Returns true if I<$file> is an image. Otherwise returns false.

=cut

sub IsImageFile {
	my ($self, $file) = @_;
	unless (-f $file) { return 0 } #It must be a file
	my ($d, $f, $e) = fileparse(lc($file), @extensions);
	if ($e ne '') { return 1 }
	return 0
}

=item B<LoadImage>I<($file)>

Loads image I<$file> and returns it as a Tk::Photo object.

=cut

sub LoadImage {
	my ($self, $file, $width, $height) = @_;
	if (defined $width) {
		$height = $width unless defined $height
	}
	if (-e $file) {
		my ($name,$path,$suffix) = fileparse(lc($file), @extensions);
		if (exists $photoext{$suffix}) {
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
# 			my $img = $self->GetAppWindow->Photo(
# 				-file => $file,
# 				-height => $size,
# 				-width => $size,
# 			);
# 			if (defined $img) {
# 				return $img
# 			}
		} elsif ($suffix eq '.svg') {
			if ($Config{osname} eq 'Win32') {
				warn "Svg images not supported on Windows";
				return undef;
			}
			my $renderer = Image::LibRSVG->new;
			$renderer->loadFromFileAtSize($file, $width, $height);
			my $png = $renderer->getImageBitmap("png", 100);
			my $img = $self->GetAppWindow->Photo(
				-data => encode_base64($png), 
				-format => 'png'
			);
			if (defined $img) {
				return $img
			}
		} else {
			warn "could not define image type for file $file"
		}
	}  else {
		warn "image file $file not found \n";
	}
	return undef
}

=item B<LoadThemeFile>I<($file)>

Loads a theme index file and returns the information in it in a hash.
It returns a reference to this hash.

=cut

sub LoadThemeFile {
	my ($self, $file) = @_;
	$file = "$file/index.theme";
	if (open(OFILE, "<", $file)) {
		my %index = ();
		my $section;
		my %inf = ();
		my $firstline = <OFILE>;
		unless ($firstline =~ /^\[.+\]$/) {
			warn "Illegal file format $file";
		} else {
			while (<OFILE>) {
				my $line = $_;
				chomp $line;
				if ($line =~ /^\[([^\]]+)\]/) { #new section
					if (defined $section) { 
						$index{$section} = { %inf }
					} else {
						$index{general} = { %inf }
					}
					$section = $1;
					%inf = ();
				} elsif ($line =~ s/^([^=]+)=//) { #new key
					$inf{$1} = $line;
				}
			}
			if (defined $section) { 
				$index{$section} = { %inf } 
			}
			close OFILE;
		}
		return \%index;
	} else {
		warn "Cannot open theme index file: $file"
	}
}

#=item B<ParentTheme>I<($theme)>
#
#Returns the parent theme index that $theme inherits.
#Returns undef if there is no parent theme.
#
#=cut

sub ParentTheme {
	my ($self, $theme) = @_;
	return $self->{THEMES}->{$theme}->{'general'}->{'Inherits'};
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






