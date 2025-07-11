#! perl

use strict;
use warnings;
use utf8;

package Text::Layout::FontConfig;

use Carp;

 our $VERSION = "0.045";

use Text::Layout::FontDescriptor;

=head1 NAME

Text::Layout::FontConfig - Pango style font description for Text::Layout

=head1 SYNOPSIS

Font descriptors are strings that identify the characteristics of the
desired font. For example, C<Sans Italic 20>.

The PDF context deals with physical fonts, e.g. built-in fonts like
C<Times-Bold> and fonts loaded from font files like
C</usr/share/fonts/dejavu/DejaVuSans.ttf>.

To map font descriptions to physical fonts, these fonts must be
registered. This defines a font family, style, and weight for the
font.

Note that Text::Layout::FontConfig is a singleton. Creating objects
with new() will always return the same object.

=cut

my %fonts;
my @dirs;
my %maps;
my $loader;
my $debug = 0;

my $weights =
  [ 100 => 'thin',
    100 => 'hairline',
    200 => 'extra light',
    200 => 'ultra light',
    300 => 'light',		# supported
    350 => 'book',		# supported
    400 => 'normal',		# supported
    400 => 'regular',		# supported
    500 => 'medium',		# supported
    600 => 'semi bold',		# supported 'semi'
    600 => 'demi bold',
    700 => 'bold',		# supported
    800 => 'extra bold',
    800 => 'ultra bold',
    900 => 'black',
    900 => 'heavy',		# supported
    950 => 'extra black',
    950 => 'ultra black',
  ];

=head2 METHODS

=over

=item new( [ atts... ] )

For convenience only. Text::Layout::FontConfig is a singleton.
Creating objects with new() will always return the same object.

Attributes:

=over

=item corefonts

If true, a predefined set of font names (the PDF corefonts) is registered.

=back

=back

=cut

sub new {
    my ( $pkg, %atts ) = @_;
    my $self = bless {} => $pkg;
    $debug = $self->{debug} = $atts{debug};
    if ( $atts{corefonts} ) {
	$self->register_corefonts;
    }
    if ( $atts{loader} ) {
	$loader = $atts{loader};
    }
    return $self;
}

sub reset {
    my ( $self ) = @_;
    warn("FC: Reset\n") if $debug;
    %fonts = ();
    @dirs = ();
    %maps = ();
}

sub debug { shift->{debug} }

=over

=item register_fonts( $font, $family, $style [ , $weight ] [ , $props ] )

Registers a font fmaily, style and weight for the given font.

$font can be the name of a built-in font, or the name of a TrueType or
OpenType font file.

$family is a font family name such as C<normal>, C<sans>, C<serif>, or
C<monospace>. It is possible to specify multiple family names, e.g.,
C<times, serif>.

$style is the slant style, one of C<normal>, C<oblique>, or C<italic>.

$weight is the font weight, like C<normal>, or C<bold>.

For convenience, style combinations like "bolditalic" are allowed.

A final hash reference can be passed to specify additional properties
for this font. Recognized properties are:

=over

=item *

C<shaping> - If set to a true value, this font will require text
shaping. This is required for fonts that deal with complex glyph
rendering and ligature handling like Devanagari.

Text shaping requires module L<HarfBuzz::Shaper>.

=item *

C<ascender> - If set overrides the font ascender.
This may be necessary to improve results for some fonts.
The value is expressed in 1/1000th of an em.

C<descender> - If set overrides the font descender.
This may be necessary to improve results for some fonts.
The value is expressed in 1/1000th of an em.

=item *

C<underline_thickness>, C<underline_position> - Overrides the font
specified or calculated values for underline thickness and/or position.
This may improve results for some fonts.

=item *

C<strikeline_thickness>, C<strikeline_position> - Overrides the font
specified or calculated values for strikeline thickness and/or position.
This may improve results for some fonts.

Note that strikeline thickness will default to underline thickness, if set.

=item *

C<overline_thickness>, C<overline_position> - Overrides the font
specified or calculated values for overline thickness and/or position.

This may improve results for some fonts.

Note that overline thickness will default to underline thickness, if
set.

=back

=back

=cut

sub register_font {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my $props;
    $props = pop(@_) if UNIVERSAL::isa( $_[-1], 'HASH' );
    my ( $font, $family, $style, $weight ) = @_;

    if ( $style && !$weight && $style =~ s/^(heavy|bold|semi(?:bold)?|medium|book|light)//i ) {
	$weight = $1;
    }
    $style  = _norm_style( $style   // "normal" );
    $weight = _norm_weight( $weight // "normal" );
    my $ff;
    if ( $font =~ /\.[ot]tf$/ ) {
	if ( $font =~ m;^/; ) {
	    $ff = $font if -r -s $font;
	}
	else {
	    foreach ( @dirs ) {
		next unless -r -s "$_/$font";
		$ff = "$_/$font";
		last;
	    }
	}
    }
    else {
	# Assume corefont.
	$ff = $font
    }

    croak("Cannot find font: ", $font, "\n") unless $ff;

    foreach ( split(/\s*,\s*/, $family) ) {
	$fonts{lc $_}->{$style}->{$weight}->{loader} = $loader;
	$fonts{lc $_}->{$style}->{$weight}->{loader_data} = $ff;
	warn("FC: Registered: $ff for ", lc($_), "-$style-$weight\n") if $debug;
	next unless $props;
	while ( my($k,$v) = each %$props ) {
	    $fonts{lc $_}->{$style}->{$weight}->{$k} = $v;
	}
    }

}

=over

=item add_fontdirs( @dirs )

Adds one or more file paths to be searched for font files.

=back

=cut

sub add_fontdirs {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my ( @d ) = @_;

    foreach ( @d ) {
	unless ( -d -r -x ) {
	    carp("Skipped font dir: $_ [$!]");
	    next;
	}
	push( @dirs, $_ );
    }
}

=over

=item register_aliases( $family, $aliases, ... )

Adds aliases for existing font families.

Multiple aliases can be specified, e.g.

    $layout->register_aliases( "times", "serif, default" );

or

    $layout->register_aliases( "times", "serif", "default" );

=back

=cut

sub register_aliases {
    use Storable qw(dclone);
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my ( $family, @aliases ) = @_;
    carp("Unknown font family: $family")
      unless exists $fonts{lc $family};
    foreach ( @aliases ) {
	foreach ( split( /\s*,\s*/, $_ ) ) {
	    $fonts{lc $_} = dclone( $fonts{lc $family} );
	}
    }
}

=over

=item register_corefonts( %options )

This is a convenience method that registers all built-in corefonts.

Aliases for families C<serif>, C<sans>, and C<monospace> are added
unless $noaliases is specified.

You do not need to call this method if you provide your own font
registrations.

Options:

=over

=item aliases

If true, register Serif, Sans and Mono as aliases for Times,
Helvetica and Courier.

This is enabled by default and can be cancelled with C<noaliases>.

=item noaliases

If true, do not register Serif, Sans and Mono as aliases for Times,
Helvetica and Courier.

=item remap

Remap the core fonts to real TrueType or OpenType font files.

Supported values are C<GNU_Free_Fonts> or C<free> to use the GNU Free Fonts
(http://ftp.gnu.org/gnu/freefont/) and C<tex> or C<tex-gyre> for the
TeX Gyre fonts (https://www.gust.org.pl/projects/e-foundry/tex-gyre/).

=back

=back

=cut

sub register_corefonts {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );

    my %options;
    if ( @_ == 1 ) {
	$options{noaliases} = shift;
    }
    else {
	%options = @_;
    }
    my $noaliases = defined($options{aliases}) ? !$options{aliases} : $options{noaliases};

    warn("FC: Registering corefonts\n") if $debug;

    register_font( "Times-Roman",           "Times"                );
    register_font( "Times-Bold",            "Times", "Bold"        );
    register_font( "Times-Italic",          "Times", "Italic"      );
    register_font( "Times-BoldItalic",      "Times", "BoldItalic"  );

    register_aliases( "Times", "Serif" )
      unless $noaliases;

    register_font( "Helvetica",             "Helvetica"                 );
    register_font( "Helvetica-Bold",        "Helvetica",  "Bold"        );
    register_font( "Helvetica-Oblique",     "Helvetica",  "Oblique"     );
    register_font( "Helvetica-BoldOblique", "Helvetica",  "BoldOblique" );

    register_aliases( "Helvetica", "Sans", "Arial" )
      unless $noaliases;

    register_font( "Courier",               "Courier"                 );
    register_font( "Courier-Bold",          "Courier",  "Bold"        );
    register_font( "Courier-Oblique",       "Courier",  "Italic"      );
    register_font( "Courier-BoldOblique",   "Courier",  "BoldItalic"  );

    register_aliases( "Courier", "Mono", "Monospace", "fixed" )
      unless $noaliases;
    register_aliases( "Courier", "Mono", "Monospace", "fixed" )
      unless $noaliases;

    register_font( "ZapfDingbats",          "Dingbats"                );

    if ( 0 ) {
    register_font( "Georgia",               "Georgia"                );
    register_font( "Georgia,Bold",          "Georgia",  "Bold"        );
    register_font( "Georgia,Italic",        "Georgia",  "Italic"      );
    register_font( "Georgia,BoldItalic",    "Georgia",  "BoldItalic"  );

    register_font( "Verdana",               "Verdana"                );
    register_font( "Verdana,Bold",          "Verdana",  "Bold"        );
    register_font( "Verdana,Italic",        "Verdana",  "Italic"      );
    register_font( "Verdana,BoldItalic",    "Verdana",  "BoldItalic"  );

    register_font( "WebDings",              "WebDings"                );
    register_font( "WingDings",             "WingDings"               );
    }

    # Corefont remapping to real font files.
    # Biggest problem is to make sure the fonts are installed, and with
    # the file names used here...
    $options{remap} //= "";

    # GNU Free Fonts.
    # http://ftp.gnu.org/gnu/freefont/freefont-ttf-20120503.zip
    if ( $options{remap} =~ /^(?:gnu[-_]?)?free(?:[-_]?fonts)?$/i ) {
	remap( 'Times-Roman'		 => "FreeSerif.ttf",
	       'Times-BoldItalic'	 => "FreeSerifBoldItalic.ttf",
	       'Times-Bold'		 => "FreeSerifBold.ttf",
	       'Times-Italic'		 => "FreeSerifItalic.ttf",
	       'Helvetica'		 => "FreeSans.ttf",
	       'Helvetica-BoldOblique'	 => "FreeSansBoldOblique.ttf",
	       'Helvetica-Bold'		 => "FreeSansBold.ttf",
	       'Helvetica-Oblique'	 => "FreeSansOblique.ttf",
	       'Courier'		 => "FreeMono.ttf",
	       'Courier-BoldOblique'	 => "FreeMonoBoldOblique.ttf",
	       'Courier-Bold'		 => "FreeMonoBold.ttf",
	       'Courier-Oblique'	 => "FreeMonoOblique.ttf",
	     );
    }

    # TeX Gyre fonts.
    # https://www.gust.org.pl/projects/e-foundry/tex-gyre/whole/tg2_501otf.zip
    elsif ( $options{remap} =~ /^tex(?:[-_]?gyre)?$/i ) {
	remap( 'Times-Roman'		 => "texgyretermes-regular.otf",
	       'Times-BoldItalic'	 => "texgyretermes-bolditalic.otf",
	       'Times-Bold'		 => "texgyretermes-bold.otf",
	       'Times-Italic'		 => "texgyretermes-italic.otf",
	       'Helvetica'		 => "texgyreheros-regular.otf",
	       'Helvetica-BoldOblique'	 => "texgyreheros-bolditalic.otf",
	       'Helvetica-Bold'		 => "texgyreheros-bold.otf",
	       'Helvetica-Oblique'	 => "texgyreheros-italic.otf",
	       'Courier'		 => "texgyrecursor-regular.otf",
	       'Courier-BoldOblique'	 => "texgyrecursor-bolditalic.otf",
	       'Courier-Bold'		 => "texgyrecursor-bold.otf",
	       'Courier-Oblique'	 => "texgyrecursor-italic.otf",
	     );
    }
    elsif ( $options{remap} ) {
	croak("Unrecognized core remap set");
    }
}

=over

=item remap($font)

=item remap( $src => $dst, ... )

Handles font remapping. The main purpose is to remap corefonts to real
fonts.

With a single argument, returns the remapped value, or undef if none.

With a hash argument, maps each of the targets (keys) to a font file
(value). This file must be present in one of the font directories.

Alternatively, the key may be one of C<Times>, C<Helvetica> and
C<Courier> and the value an already registered family.

=back

=cut

sub remap {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );

    return $maps{$_[0]} if @_ == 1;

    my %m = @_;
    while ( my ($k, $v ) = each %m ) {

	# Check for family map.
	if ( $k =~ /^(Courier|Times|Helvetica)$/
	     && defined $fonts{lc $v} ) {
	    if ( $k eq 'Courier' ) {
		$maps{'Courier'}	       = $fonts{lc $v}{normal}{normal}{loader_data};
		$maps{'Courier-Bold'}	       = $fonts{lc $v}{normal}{bold}{loader_data};
		$maps{'Courier-Oblique'}       = $fonts{lc $v}{italic}{normal}{loader_data};
		$maps{'Courier-BoldOblique'}   = $fonts{lc $v}{italic}{bold}{loader_data};
	    }
	    elsif ( $k eq 'Helvetica' ) {
		$maps{'Helvetica'}	       = $fonts{lc $v}{normal}{normal}{loader_data};
		$maps{'Helvetica-Bold'}	       = $fonts{lc $v}{normal}{bold}{loader_data};
		$maps{'Helvetica-Oblique'}     = $fonts{lc $v}{italic}{normal}{loader_data};
		$maps{'Helvetica-BoldOblique'} = $fonts{lc $v}{italic}{bold}{loader_data};
	    }
	    elsif ( $k eq 'Times' ) {
		$maps{'Times-Roman'}	       = $fonts{lc $v}{normal}{normal}{loader_data};
		$maps{'Times-Bold'}	       = $fonts{lc $v}{normal}{bold}{loader_data};
		$maps{'Times-Italic'}	       = $fonts{lc $v}{italic}{normal}{loader_data};
		$maps{'Times-BoldItalic'}      = $fonts{lc $v}{italic}{bold}{loader_data};
	    }
	    next;
	}

	# Map font to corefont.
	my $ff;
	if ( $v =~ m;^/; ) {
	    $ff = $v if -r -s $v;
	}
	else {
	    foreach ( @dirs ) {
		next unless -r -s "$_/$v";
		$ff = "$_/$v";
		last;
	    }
	}

	$maps{$k} = $ff
	  or carp("Invalid font mapping ($v: $!)")

      }

    1;
}

=over

=item find_font( $family, $style, $weight )

Returns a font descriptor based on the given family, style and weight.

On Linux, fallback using fontconfig.

=back

=cut

sub find_font {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my $atts;
    $atts = pop(@_) if UNIVERSAL::isa( $_[-1], 'HASH' );
    my ( $family, $style, $weight ) = @_;
    warn("FC: find_font( $family, $style, $weight )\n") if $debug;

    my $try = sub {
	if ( $fonts{$family}
	     && $fonts{$family}->{$style}
	     && $fonts{$family}->{$style}->{$weight} ) {

	    my $ff = $fonts{$family}->{$style}->{$weight};
	    my %i = ( family => $family,
		      style  => $style,
		      weight => $weight );
;
	    if ( $ff->{font} ) {
		$i{font} = $ff->{font};
	    }
	    elsif ( $ff->{loader_data} ) {
		$i{loader_data} = $ff->{loader_data};
		$i{loader}      = $loader;
		$i{cache}       = $ff;
	    }
	    else {
		return;
	    }

	    for ( qw( shaping ascender descender nosubset direction language
		      underline_thickness underline_position
		      strikeline_thickness strikeline_position
		      overline_thickness overline_position
		   ) ) {
		$i{$_} = $ff->{$_};
	    }

	    if ( $debug ) {
		warn("FC: found( $i{family}, $i{style}, $i{weight} ) -> ",
		     $i{loader_data}, "\n");
	    }
	    return Text::Layout::FontDescriptor->new(%i);
	}
    };

    $style  = _norm_style( $style   // "normal" );
    $weight = _norm_weight( $weight // "normal" );
    my $res = $try->();
    return $res if $res;

    # TODO: Some form of font fallback.
    if ( _fallback( $family, $style, $weight ) ) {
	$res = $try->();
	return $res if $res;
    }

    # Nope.
    croak("Cannot find font: $family $style $weight\n");
}

=over

=item from_string( $description )

Returns a font descriptor using a Pango-style font description, e.g.
C<Sans Italic 14>.

On Linux, fallback using fontconfig.

=back

=cut

my $stylep  = qr/^(?:heavy|bold|semi(?:bold)?|medium|book|light)? (oblique|italic)$/ix;
my $weightp = qr/^(heavy|bold|semi(?:bold)?|medium|book|light) (?:oblique|italic)?$/ix;

sub from_string {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my ( $description ) = @_;

    my $i = parse($description);

    my $res = find_font( $i->{family}, $i->{style}, $i->{weight} );
    $res->set_size($i->{size}) if $res && $i->{size};
    $res;
}

=over

=item parse( $description )

Parses a Pango-style font description and returns a hash ref with keys
C<family>, C<style>, C<weight>, and C<size>.

Unspecified items are returned as empty strings or, in the case of
C<size>, zero.

=back

=cut

sub parse {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my ( $description ) = @_;

    my $family = "";
    my $style  = "";
    my $weight = "";
    my $size   = 0;

    my @p = split( ' ', $description );
    $size = pop(@p) if $p[-1] =~ /^\d+(?:\.\d+)?$/;

    for ( @p ) {
	my $t = lc;
	if ( ! $family ) {
	    $family = $t;
	}
	elsif ( $t =~ $stylep ) {
	    $style = "italic";
	    $weight = $1 if $t =~ $weightp;
	}
	elsif ( $t =~ $weightp ) {
	    $weight = $1;
	    $style = $1 if $t =~ $stylep;
	}
	elsif ( $t eq "normal" ) {
	    $style = $weight = "";
	}
	else {
	    carp("Unknown font property: $t");
	    $family .= " " . $_;
	}
    }

    return { family => $family,
	     style  => $style,
	     weight => $weight,
	     size   => $size,
	   };
}

=over

=item from_filename( $filename )

Returns a font descriptor from a filename. Tries to infer Pango data
from the name.

=back

=cut

use File::Basename;

sub from_filename {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my ( $file, $size ) = @_;
    ( $file, my $sel ) = ( $1, $2 ) if $file =~ /^(.*\.ttc)(:.*)/;
    ( my $b, undef, undef ) = fileparse( $file, qr/\.\w+/ );
    my ( $family, $style, $weight ) = ( $b, "normal", "normal" );

    if ( lc($b) =~ m/^
		 ( .*? )
		 -?
		 (roman?|normal|regular)?
		 (light|book|medium|semi(?:bold)?|bold|heavy)?
		 (italic|ital|oblique|obli)?
		 $/ix ) {
	$family = $1       if $1;
	$style  = "italic" if $4;
	$weight = $3       if $3;
    }

    my $fd = Text::Layout::FontDescriptor->new
      ( loader_data => $file.($sel//""),
	loader => $loader,
	family => $family,
	style  => $style,
	weight => $weight,
	$size ? ( size => $size ) : (),
      );

    $fonts{$family}{$style}{$weight} //= $fd;

    return $fd;
}

################ Helper Routines ################

sub set_loader {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    $loader = shift;
    croak("Font loader must be a code reference")
      unless UNIVERSAL::isa( $loader, "CODE" );
}

# Normalize (and check) a style specification.

sub _norm_style {
    my ( $style ) = @_;
    $style = lc $style;
    return "italic" if $style =~ $stylep;

    carp("Unhandled font style: $style\n")
      unless $style =~ /^(regular|normal)?$/;

    return "normal";
}

# Normalize (and check) a weight specification.

sub _norm_weight {
    my ( $weight ) = @_;
    $weight = lc $weight;
    return $1 if $weight =~ $weightp;

    carp("Unhandled font weight: $weight\n")
      unless $weight =~ /^(regular|normal)?$/;

    return "normal";
}

my $fallback;

sub _fallback {
    unless ( defined $fallback ) {
	$fallback = '';
	foreach ( split( /:/, $ENV{PATH} ) ) {
	    next unless -f -x "$_/fc-match";
	    $fallback = "$_/fc-match";
	    last;
	}
    }
    return unless $fallback;

    my ( $family, $style, $weight ) = @_;
    warn("FC: fallback( $family, $style, $weight )\n") if $debug;

    my $pattern = $family;
    $pattern .= ":$style" if $style;
    $pattern .= ":$weight" if $weight;

    open( my $fd, '-|',
	  $fallback, '-s', '--format=%{file}\n', $pattern )
      or do { $fallback = ''; return };

    my $res;
    local $_;
    while ( <$fd> ) {
	chomp;
	next unless -f -r $_;
	next unless /\.[ot]tf$/i;
	$res = $_;
	last;
    }

    close($fd);
    register_font( $res, $family, $style, $weight ) if $res;
    warn("FC: Lookup $pattern -> $res\n") if $debug;
    return $res;
}

=head1 SEE ALSO

L<Text::Layout>, L<Text::Layout::FontDescriptor>.

=head1 AUTHOR

Johan Vromans, C<< <JV at CPAN dot org> >>

=head1 SUPPORT

This module is part of <Text::Layout>.

Development takes place on GitHub:
L<https://github.com/sciurius/perl-Text-Layout>.

You can find documentation for this module with the perldoc command.

  perldoc Text::Layout::FontConfig

Please report any bugs or feature requests using the issue tracker for
Text::Layout on GitHub.

=head1 LICENSE

See L<Text::Layout>, L<Text::Layout::FontDescriptor>, L<HarfBuzz::Shaper>.

=cut

sub _dump {
    foreach my $family ( sort keys %fonts ) {
	foreach my $style ( qw( normal italic ) ) {
	    foreach my $weight ( qw( normal light book medium semi semibold bold heavy ) ) {
		my $f = $fonts{$family}{$style}{$weight};
		next unless $f;
		printf STDERR ( "%-13s %s%s%s%s%s %s\n",
				$family,
				$style eq 'normal' ? "-" : "i",
				$weight eq 'bold' ? "b"
				: $weight eq 'light' ? "l"
				: $weight eq 'book' ? "k"
				: $weight eq 'medium' ? "m"
				: $weight eq 'semi' ? "s"
				: $weight eq 'semibold' ? "s"
				: $weight eq 'heavy' ? "h"
				: "-",
				$f->{shaping} ? "s" : "-",
				$f->{interline} ? "l" : "-",
				$f->{font} ? "+" : " ",
				$f->{loader_data},
			      );
	    }
	}
    }
}

# END { _dump }

1;
