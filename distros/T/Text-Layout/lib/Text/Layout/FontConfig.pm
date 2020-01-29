#! perl

use strict;
use warnings;
use utf8;

package Text::Layout::FontConfig;

use Carp;



our $VERSION = "0.015";

use Text::Layout::FontDescriptor;

=head1 NAME

Text::Layout::FontConfig - Pango style font description for Text::Layout

=head1 SYNOPSIS

Font descriptors are strings that identify the characteristics of the
desired font. For example, C<Sans Italic 20>.

The PDF context deals with fysical fonts, e.g. built-in fonts like
C<Times-Bold> and fonts loaded from font files like
C</usr/share/fonts/dejavu/DejaVuSans.ttf>.

To map font descriptions to fysical fonts, these fonts must be
registered. This defines a font family, style, and weight for the
font.

Note that Text::Layout::FontConfig is a singleton. Creating objects
with new() will always return the same object.

=cut

my %fonts;
my @dirs;
my $loader;
my $debug = 0;

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
    my $self = bless \my $i => $pkg;
    if ( $atts{corefonts} ) {
	$self->register_corefonts;
    }
    if ( $atts{loader} ) {
	$loader = $atts{loader};
    }
    return $self;
}

=over

=item register_fonts( $font, $family, $style, $weight )

Registers a font fmaily, style and weight for the given font.

$font can be the name of a built-in font, or the name of a TrueType or
OpenType font file.

$family is a font family name such as C<normal>, C<sans>, C<serif>, or
C<monospace>. It is possible to specify multiple family names, e.g.,
C<times, serif>.

$style is the slant style, one of C<normal>, C<oblique>, or C<italic>.

$weight is the font weight, like C<normal>, or C<bold>.

For convenience, style combinations like "bolditalic" are allowed.

=back

=cut

sub register_font {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my $atts;
    $atts = pop(@_) if UNIVERSAL::isa( $_[-1], 'HASH' );
    my ( $font, $family, $style, $weight ) = @_;

    if ( $style && !$weight && $style =~ s/^bold//i ) {
	$weight = "bold";
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
	next unless $atts;
	while ( my($k,$v) = each %$atts ) {
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
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my ( $family, @aliases ) = @_;
    carp("Unknown font family: $family")
      unless exists $fonts{lc $family};
    foreach ( @aliases ) {
	foreach ( split( /\s*,\s*/, $_ ) ) {
	    $fonts{lc $_} = $fonts{lc $family};
	}
    }
}

=over

=item register_corefonts( $noaliases )

This is a convenience method that registers all built-in corefonts.

Aliases for families C<serif>, C<sans>, and C<monospace> are added
unless $noaliases is specified.

You do not need to call this method if you provide your own font
registrations.

=back

=cut

sub register_corefonts {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my ( $noaliases ) = @_;

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

    my $try = sub {
      if ( $fonts{$family}
	 && $fonts{$family}->{$style}
	 && $fonts{$family}->{$style}->{$weight} ) {
	my $ff;
	if ( $ff = $fonts{$family}->{$style}->{$weight}->{font} ) {
	    return Text::Layout::FontDescriptor->new
	      ( font   => $ff,
		family => $family,
		style  => $style,
		weight => $weight,
		shaping => $fonts{$family}->{$style}->{$weight}->{shaping},
		interline => $fonts{$family}->{$style}->{$weight}->{interline},
	      );
	}
	elsif ( $ff = $fonts{$family}->{$style}->{$weight}->{loader_data} ) {
	    return Text::Layout::FontDescriptor->new
	      ( loader_data => $ff,
		loader => $loader,
		cache  => $fonts{$family}->{$style}->{$weight},
		family => $family,
		style  => $style,
		weight => $weight,
		shaping => $fonts{$family}->{$style}->{$weight}->{shaping},
		interline => $fonts{$family}->{$style}->{$weight}->{interline},
	     );
	}
	else {
	    return;
	}
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

my $stylep  = qr/^( (?:bold)? (?:oblique|italic)  )$/ix;
my $weightp = qr/^( (?:bold)  (?:oblique|italic)? )$/ix;

sub from_string {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my ( $description ) = @_;

    my $i = parse($description);

    my $res = find_font( $i->{family}, $i->{style}, $i->{weight} );
    $res->set_size($i->{size}) if $res && $i->{size};
    $res;
}

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
	}
	elsif ( $t =~ $weightp ) {
	    $weight = "bold";
	}
	elsif ( $t eq "normal" ) {
	    $style = $weight = "";
	}
	else {
	    carp("Unknown font property: $t");
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
    my ( $file ) = @_;
    my $b;
    ( $b, undef, undef ) = fileparse( $file, qr/\.\w+/ );
    my ( $family, $style, $weight ) = ( $b, "normal", "normal" );

    if ( lc($b) =~ m/^
		 ( .*? )
		 -?
		 (roman?|normal|regular)?
		 (light|book|bold)?
		 (italic|ital|oblique|obli)?
		 $/ix ) {
	$family = $1       if $1;
	$style  = "italic" if $4;
	$weight = "bold"   if $3 && $3 =~ /^(bold)$/;
    }

    my $fd = Text::Layout::FontDescriptor->new
      ( loader_data => $file,
	loader => $loader,
	family => $family,
	style  => $style,
	weight => $weight );

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
    return "bold" if $weight =~ $weightp;

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

    my $pattern = $family;
    $pattern .= ":$style" if $style;
    $pattern .= ":$weight" if $weight;

    open( my $fd, '-|',
	  $fallback, '-s', '--format=%{file}\n', $pattern )
      or do { $fallback = ''; return };

    my $res;
    while ( <$fd> ) {
	chomp;
	next unless -f -r $_;
	next unless /\.[ot]tf$/i;
	$res = $_;
	last;
    }

    close($fd);
    register_font( $res, $family, $style, $weight ) if $res;
    warn("Lookup $pattern -> $res\n") if $debug;
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

Please report any bugs or feature requests using the issue tracker on
GitHub.

=head1 LICENSE

See L<Text::Layout>.

=cut

sub _dump {
    foreach my $family ( sort keys %fonts ) {
	foreach my $style ( qw( normal italic ) ) {
	    foreach my $weight ( qw( normal bold ) ) {
		my $f = $fonts{$family}{$style}{$weight};
		next unless $f;
		printf STDERR ( "%-13s %s%s%s%s%s %s\n",
				$family,
				$style eq 'normal' ? "-" : "i",
				$weight eq 'normal' ? "-" : "b",
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
