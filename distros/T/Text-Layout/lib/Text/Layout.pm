#! perl

use strict;
use warnings;
use utf8;

package Text::Layout;

use Carp;

 our $VERSION = "0.045";

=head1 NAME

Text::Layout - Pango style markup formatting

This module will cooperate with PDF::API2, PDF::Builder, Cairo, and Pango.

=head1 SYNOPSIS

Text::Layout provides methods for Pango style text formatting. Where
possible the methods have identical names and (near) identical
behaviour as their Pango counterparts.

See L<https://developer.gnome.org/pango/stable/pango-Layout-Objects.html>.

The package uses Text::Layout::FontConfig (included) to organize fonts
by description.

If module HarfBuzz::Shaper is installed, Text::Layout can use it for
text shaping.

Example, using PDF::API2 integration:

    use PDF::API2;		# or PDF::Builder
    use Text::Layout;

    # Create a PDF document.
    my $pdf = PDF::API2->new;	# or PDF::Builder->new
    $pdf->default_page_size("a4")	# ISO A4

    # Set up page and get the text context.
    my $page = $pdf->page;
    my $ctx  = $page->text;

    # Create a markup instance.
    my $layout = Text::Layout->new($pdf);

    # This example uses PDF corefonts only.
    Text::Layout::FontConfig->register_corefonts;

    $layout->set_font_description(Text::Layout::FontConfig->from_string("times 40"));
    $layout->set_markup( q{The <i><span foreground="red">quick</span> <span size="20"><b>brown</b></span></i> fox} );

    # Center text.
    $layout->set_width(595);	# width of A4 page
    $layout->set_alignment("center");

    # Render it.
    $layout->show( 0, 600, $ctx );
    $pdf->save("out.pdf");

All PDF::API2 graphic and text methods can still be used, they won't
interfere with the layout methods.

=head1 NOTES FOR PDF::API2/Builder USERS

=head2 Baselines

PDF::API2 and PDF::Builder render texts using the font baseline as origin.

This module typesets text in an area of possibly limited width and
height. The origin is the top left of this area. Currently this area
contains only a single line of text. This will change in the future
when line breaking and paragraph formatting is implemented.

PDF::API2 and PDF::Builder coordinates have origin bottom left. This
module produces information with respect to top left coordinates.

=head1 IMPORTANT NOTES FOR PANGO USERS

=head2 Coordinate system

Pango, layered upon Cairo, uses a coordinate system that starts off
top left. So for western text the direction is increasing I<x> and
increasing I<y>.

PDF::API2 uses the coordinate system as defined in the PDF
specification. It starts off bottom left. For western text the
direction is increasing I<x> and B<de>creasing I<y>.

=head1 Pango Conformance Mode

Text::Layout can operate in one of two modes: I<convenience mode>
(enabled by default), and I<Pango conformance mode>. The desired mode
can be selected by calling the method set_pango_scaling().

=head2 Pango coordinates

Pango uses two device coordinates units: Pango units and device units.
Pango units are 1024 (C<PANGO_SCALE>) times the device units.

Several methods have two variants, e.g. get_size() and
get_pixel_size(). The pixel-variant uses device units while the other
variant uses Pango units.

In I<convenience mode>, this module assumes no scaling. All units are
PDF device units (1/72 inch).

=head2 Pango device units

Device units are used for font rendering. Pango device units are 96dpi
while PDF uses 72dpi.

In I<convenience mode> this is ignored. E.g. a C<Times 20> font 
will be of equal size in the two systems,

In I<Pango conformance mode> you would need to specify a font size of
C<15360> to get a 20pt font.

=head1 SUPPORTED MARKUP

Text::Layout recognizes most of the Pango markup as provided by the
Pango library version 1.50 or newer. However, not everything is supported.

=head2 Span attributes

=over 8

=item font="I<DESC>"   font_desc="I<DESC>"

Specifies a font to be used, e.g. C<Serif 20>.

=item font_face="I<FAM>"   face="I<FAM>"

Specifies a font family to be used.

=item font_family="I<FAM>"

Same as font_face="I<FAM>".

=item size=I<FNUM>   size=I<FNUM>pt   size=I<FNUM>%

Font size in 1024ths of a point (conformance mode), or in points (e.g.
'12.5pt'), or a percentage (e.g. '200%'), or one of the relative sizes
'smaller' or 'larger'.

Note that in Pango conformance mode, the actual font size is 96/72
larger. So C<"45pt"> gives a 60pt font.

=item style="I<STYLE>"   font_style="I<STYLE>"

Specifes the font style, e.g. C<italic>.

=item weight="I<WEIGHT>"   font_weight="I<WEIGHT>"

Specifies the font weight, e.g. C<bold>.

=item foreground="I<COLOR>"   fgcolor="I<COLOR>"   color="I<COLOR>"

Specifies the foreground colour, e.g. C<black>.

=item background="I<COLOR>"   bgcolor="I<COLOR>"

Specifies the background colour, e.g. C<white>.

=item underline="I<TYPE>"

Enables underlining.
I<TYPE> must be C<none>, C<single>, or C<double>.

=item underline_color="I<COLOR>"

The colour to be used for underlining, if enabled.

=item overline="I<TYPE>"

Enables overlining.
I<TYPE> must be C<none>, C<single>, or C<double>.

=item overline_color="I<COLOR>"

The colour to be used for ovderlining, if enabled.

=item strikethrough="I<ARG>"

Enables or disables overlining. I<ARG> must be C<true> or C<1> to
enable, and C<false> or C<0> to disable.

=item strikethrough_color="I<COLOR>"

The colour to be used for striking, if enabled.

=item rise=C<NUM>

In convenience mode, lowers the text by I<NUM>/1024 of the font size.
May be negative to rise the text.

In Pango conformance mode, rises the text by I<NUM> units from the baseline.
May be negative to lower the text.

Note: In Pango conformance mode, C<rise> does B<not> accumulate.
 Use C<baseline_shift> instead.

=item rise=C<NUM>pt   rise=C<NUM>%   rise=C<NUM>em   rise=C<NUM>ex

Rises the text from the baseline. May be negative to lower the text.

Units are points if postfixed by B<pt>, and a percentage of the current font size if postfixed by B<%>.

B<em> units are equal to the current font size, B<ex> half the font size.

Note: This is not (yet?) part of the Pango markup standard.

=item baseline_shift=C<NUM>   beseline_shift=C<NUM>pt   baseline_shift=C<NUM>%

Like C<rise>, but accumulates.

=back

Also supported but not part of the official Pango Markup specification.

=over 8

=item href="C<TARGET>"

Creates a clickable target that activates the I<TARGET>.

The I<TARGET> can be:

=over 4

=item *

The name of an external PDF document, e.g. C<"that.pdf">.

=item *

A named destination in the document, e.g. C<"#there">.
See L<Strut attributes>.

=item *

a named destination in an external document, e.g. C<"that.pdf#there">.

=back

=back

=head2 Img (image) attributes

I<This is an extension to Pango markup.>

Note that image markup elements may only occur as closed elements,
i.e., C<< <img/> >>.

=over 8

=item id="I<ID>"

Implementation dependent.

=item src="I<URI>"

Source filename or url for the image.

=item width="I<WIDTH>" (short: w="I<WIDTH>")

The width the image should be considered to occupy, regardless its
actual dimensions.

=item height="I<HEIGHT>" (short: h="I<HEIGHT>")

The height the image should be considered to occupy, regardless its
actual dimensions.

=item x="I<XDISP>"

Horizontal displacement of the image relative to the C<< <img/> >> element.

=item y="I<YDISP>"

Vertical displacement of the image relative to the C<< <img/> >> element.

=item border="I<THICK>"

Provide a border around the element. I<THICK> denotes its thickness.

=back

=head2 Strut attributes

I<This is an extension to Pango markup.>

A C<strut> is a markup element that has bounding box dimensions but no
ink dimensions.

Note that strut markup elements may only occur as closed elements,
i.e., C<< <strut/> >>.

=over 8

=item label="I<LABEL>"

An optional identifying label.

When a label is used, this will create a I<named destination>, a
symbolic name for a location in the document.
See the C<span> C<href> attribute,

=item width="I<WIDTH>" (short w="I<WIDTH>")

The width of the strut. Default value is zero.

Width may be expressed in points, C<em> (font size) or C<ex> (half of
font size).

=item ascender="I<ASC>" (short: a="I<ASC>")

The ascender of the strut. Optional.

May be expressed in points, C<em> (font size) or C<ex> (half of
font size).

=item descender="I<DESC>" (short: d="I<DESC>")

The descender of the strut. Optional.

May be expressed in points, C<em> (font size) or C<ex> (half of
font size).

=back

=head2 Shortcuts

Equivalent C<span> attributes for shortcuts.

=over 8

=item b

weight=bold

=item big

larger

=item emp

style=italic

=item i

style=italic

=item s

strikethrough=true

=item small

size=smaller

=item strong

weight=bold

=item sub

size=smaller rise=-30%

=item sup

size=smaller rise=30%

=item tt

face=monospace

=item u

underline=single

=back

=cut

use constant {
    PANGO_SCALE		=> 1024,
    PANGO_DEVICE_UNITS	=>   96,
    PDF_DEVICE_UNITS	=>   72,
};

# Default is no Pango scaling.
sub px2pu { $_[0] };
sub pu2px { $_[0] };

use Text::Layout::FontConfig;
use Text::Layout::Utils qw(parse_kv);

# Global (persistent) shortcodes.
# These map <XX> -> <span YY>.
my %shortcodes =
  ( b	    => "weight=bold",
    big	    => "size=larger",
    emp	    => "style=italic",
    i	    => "style=italic",
    s	    => "strikethrough=true",
    small   => "size=smaller",
    strong  => "weight=bold",
    sub	    => "size=smaller rise=-30%",
    sup	    => "size=smaller rise=30%",
    tt	    => "face=monospace",
    u	    => "underline=single",
);

=head1 METHODS

=over

=item new( $pdf )

Creates a new layout instance for PDF::API2. This is for convenience.
It is equivalent to

    use Text::Layout::PDFAPI2;
    $layout = Text::Layout::PDFAPI2->new($pdf);

For other implementations only the above method can be used.

The argument is the I<context> for text formatting. In the case of
PDF::API2 this will be a PDF::API2 object.

=back

=cut

sub new {
    my ( $pkg, @data ) = @_;

    $pkg =~ s/::$//;
    if ( $pkg eq __PACKAGE__ ) {
	# For convenience (and backward compatibility)...
	unless ( @data >= 1 && ref($data[0]) =~ /^PDF::(API2|Builder)\b/ ) {
	    croak("Please instantiate a backend, e.g. ".__PACKAGE__."::PDFAPI2");
	}
	require Text::Layout::PDFAPI2;
	return Text::Layout::PDFAPI2->new(@data); # CUL8R
    }
    bless { _context => undef,
	    _fonts   => {},
	    _content => [],
	    _px2pu   => \&px2pu,
	    _pu2px   => \&pu2px,
	    _pango   => 0,
	    _sc	     => {},
	  } => $pkg;
}

=over

=item copy

Copies (clones) a layout instance.

The content is copied deeply, the context and fonts are copied by
reference.

=back

=cut

sub copy {
    my ( $self ) = @_;

    my $copy = bless { %$self } => ref($self);
    $copy->{_content} = [];
    for ( @{ $self->{_content} } ) {
	my %h;
	@h{ keys %$_ } = values %$_;
	push( @{ $copy->{_content} }, { %h } );
    }
    $copy->{_sc} = { %{ $self->{_sc} } };
    return $copy;
}

=over

=item get_context

Gets the context of this layout.

=back

=cut

sub get_context {
    my ( $self ) = ( $_ );
    $self->{_context};
}

=over

=item context_changed

Not supported.

=back

=cut

sub context_changed { nyi() }

=over

=item get_serial

Not supported.

=back

=cut

sub get_serial { nyi() }

=over

=item set_text( $text )

Puts a string in this layout instance. No markup is processed.

Note that if you have used set_markup() on this layout before, you may
want to call set_attributes() to clear the attributes set on the
layout from the markup as this function does not clear all attributes.

=back

=cut

sub set_text {
    my ( $self, $string ) = @_;
    $self->{_content} =
      [ { type  => "text",
	  text  => $string,
	  font  => $self->{_currentfont},
	  size  => $self->{_currentsize},
	  color => $self->{_currentcolor},
	  base  => 0,
	} ];
    delete( $self->{_bbcache} );
    delete( $self->{_struts} );
}

=over

=item get_text

Gets the content of this layout instance as a single string.
Markup is ignored.

Returns undef if no text has been set.

=back

=cut

sub get_text {
    my ( $self ) = @_;
    return unless $self->{_content};
    join( "", map { $_->{text} } @{ $self->{_content} } );
}

=over

=item get_character_count

Returns the number of characters in the text of this layout.

Basically the same as length of get_text().

Returns undef if no text has been set.

=back

=cut

sub get_character_count {
    my ( $self ) = @_;
    return unless $self->{_content};
    my $len = 0;
    $len += length($_->{text}) for @{ $self->{_content} };
    return $len;
}

=over

=item set_markup( $string )

Puts a string in this layout instance.

The string can contain Pango-compatible markup. See
L<https://developer.gnome.org/pygtk/stable/pango-markup-language.html>.

Implementation note: Although all markup is parsed, not all is implemented.

=back

=cut

use Text::ParseWords;
use constant STEP => 0.83333125;	# Cf. Pango

my %magstep =
  ( "xx-small"	=> 1.0*STEP*STEP*STEP,
    "x-small"	=> 1.0*STEP*STEP,
    "small"	=> 1.0*STEP,
    "smaller"	=> 1.0*STEP,
    "medium"	=> 1.0,
    "large"	=> 1.0/STEP,
    "larger"	=> 1.0/STEP,
    "x-large"	=> 1.0/(STEP*STEP),
    "xx-large"  => 1.0/(STEP*STEP*STEP),
  );

sub set_markup {
    my ( $self, $string ) = @_;
    confess("set_markup with UNDEF") unless defined $string;
    my @stack;
    my @content;
    my $fcur = $self->{_currentfont};
    my $fcol = $self->{_currentcolor};
    my $fsiz = $self->{_currentsize};
    my $href;
    my $undl;
    my $uncl = $fcol;
    my $ovrl;
    my $ovcl = $fcol;
    my $strk;
    my $stcl = $fcol;
    my $bcol;
    my $base = 0;

    my $try_size = sub {
	my ( $k ) = @_;
	if ( exists $magstep{$k} ) {
	    $fsiz *= $magstep{$k};
	}
	elsif ( $k =~ /^(smaller)$/ ) {
	    $fsiz *= STEP;
	}
	elsif ( $k =~ /^(larger)$/ ) {
	    $fsiz /= STEP;
	}
	else {
	    return;		# fail
	}
	return 1;		# success
    };

    my $span;
    $span = sub {
	my ( $v ) = @_;

	# Split the span attributes. Note that shellwords is so kind to
	# split 'font="xx yy"' as a single word 'font=xx yy'.
	# NOTE: can't use parse_kv -- order is important
	foreach my $k ( shellwords($v) ) {

	    # key=value
	    if ( $k =~ /^([-\w]+)=(.+)$/ ) {
		my ( $k, $v ) = ( $1, $2 );

		# Ignore case unless required.
		$v = lc $v unless $k =~ /^(link|href|a)$/;

		# <span font_desc="Sans 20">
		if ( $k =~ /^(font|font_desc)$/ ) {
		    $fcur = Text::Layout::FontConfig->from_string($v);
		    $fsiz = $fcur->get_size if $fcur->get_size;
		}

		# <span face="Sans">
		elsif ( $k =~ /^(face|font_face|font_family)$/ ) {
		    $fcur = Text::Layout::FontConfig->find_font( $v,
								 $fcur->{style},
								 $fcur->{weight});
		}

		# <span size=20>
		elsif ( $k =~ /^(size|font_size)$/ ) {
		    if ( $try_size->($v) ) {
			#ok
		    }
		    elsif ( $v =~ /^(\d+(?:\.\d+)?)pt$/ ) {
			$fsiz = $self->{_pango}
			  ? $1 * PANGO_DEVICE_UNITS / PDF_DEVICE_UNITS
			  : $1;
			# warn("fsiz \"$v\" -> $fsiz\n");
		    }
		    elsif ( $v =~ /^\d+(?:\.\d+)?$/ ) {
			$fsiz = $self->{_pango}
			  ? $v * PANGO_DEVICE_UNITS / PDF_DEVICE_UNITS / PANGO_SCALE
			  : $v;
			# warn("fsiz \"$v\" -> $fsiz\n");
		    }
		    elsif ( $v =~ /^(\d+(?:\.\d+)?)\%$/ ) {
			$fsiz *= $1 / 100;
			# warn("fsiz \"$v\" -> $fsiz\n");
		    }
		    else {
			carp("Invalid size: \"$v\"\n");
		    }
		}

		# <span style="Italic">
		elsif ( $k =~ /^(style|font_style)$/ ) {
		    $v = Text::Layout::FontConfig::_norm_style($v);
		    $fcur = Text::Layout::FontConfig->find_font( $fcur->{family},
					      $v, $fcur->{weight} );
		}

		# <span weight="bold">
		elsif ( $k =~ /^(weight|font_weight)$/ ) {
		    $v = Text::Layout::FontConfig::_norm_weight($v);
		    $fcur = Text::Layout::FontConfig->find_font( $fcur->{family},
					      $fcur->{style}, $v );
		}

		# <span variant="...">
		# <span stretch="...">
		elsif ( $k =~ /^(?:font_)?(variant|stretch)$/ ) {
		    # ignore for now
		}
		elsif ( $k =~ /^(features|background_alpha|alpha)$/ ) {
		    # ignore for now
		}

		# <span foreground="red">
		elsif ( $k =~ /^(foreground|fgcolor|color)$/ ) {
		    $fcol = $v;
		}

		# <span background="red">
		elsif ( $k =~ /^(background|bgcolor)$/ ) {
		    $bcol = $v;
		}

		# <span underline="double">
		elsif ( $k eq "underline" && $v =~ /^(none|single|double)$/i ) {
		    $undl = lc $v;
		}
		elsif ( $k eq "underline_color" ) {
		    $uncl = lc $v;
		}

		# <span overline="double">
		elsif ( $k eq "overline" && $v =~ /^(none|single|double)$/i ) {
		    $ovrl = lc $v;
		}
		elsif ( $k eq "overline_color" ) {
		    $ovcl = lc $v;
		}

		# <span rise=324>
		elsif ( $k eq "rise" ) {
		    if ( $v =~ /^(-?\d+(?:\.\d*)?)pt$/ ) {
			$base = -$1;
		    }
		    elsif ( !$self->{_pango} && $v =~ /^(-?\d+(?:\.\d*)?)\%$/ ) {
			$base = -$1 * $fsiz / 100;
		    }
		    elsif ( !$self->{_pango} && $v =~ /^(-?\d+(?:\.\d*)?)e([mx])$/ ) {
			$base = $2 eq 'x' ? -$1 * $fsiz / 2 : -$1 * $fsiz;
		    }
		    else {
			$v /= PANGO_SCALE;
			$base = $self->{_pango} ? -$v : $base + $v * $fsiz;
		    }
		}

		# <span baseline_shift=324>
		# Line rise, but accumulate.
		elsif ( $k eq "baseline_shift" ) {
		    if ( $v =~ /^(-?\d+(?:\.\d*)?)pt$/ ) {
			$base -= $1;
		    }
		    elsif ( $v =~ /^(-?\d+(?:\.\d*)?)\%$/ ) {
			$base -= $1 * $fsiz / 100;
		    }
		    elsif ( $v =~ /^(-?\d+(?:\.\d*)?)e([mx])$/ ) {
			$base = $2 eq 'x' ? $1 * $fsiz / 2 : $1 * $fsiz;
		    }
		    else {
			$base -= $self->{_pango} ? $v : -$v * $fsiz;
		    }
		}

		# <span strikethrough=false>
		elsif ( $k eq "strikethrough" && $v =~ /^(true|1)$/i ) {
		    $strk = 1;
		}
		elsif ( $k eq "strikethrough" && $v =~ /^(false|0)$/i ) {
		    $strk = 0;
		}
		elsif ( $k eq "strikethrough_color" ) {
		    $stcl = $v;
		}

		# <span fallback=false>
		elsif ( $k eq "fallback" ) {
		    # Not supported.
		}

		# <span lang="en">
		elsif ( $k eq "lang" ) {
		    # Not supported.
		}

		# <span href="...">
		elsif ( $k eq "href" ) {
		    $href = $v;
		}
	    }

	    # <span strikethrough>
	    elsif ( $k eq "strikethrough" ) {
		$span->("strikethrough=true");
	    }

	    # <span fallback>
	    elsif ( $k eq "fallback" ) {
		$span->("fallback=true");
	    }

	    else {
		carp("Invalid span markup: \"$k\"\n");
	    }
	}
    };

    my $image = sub {
	my ( $v ) = @_;

	my %img;
	# Split the attributes.
	while ( my ( $k, $v ) = each %{parse_kv($v)} ) {

	    # Ignore case unless required.
	    $v = lc $v unless $k =~ /^(src|id)$/;

	    if ( $k eq "src" ) {
		$img{src} = $v;
	    }
	    elsif ( $k eq "id" ) {
		$img{id} = $v;
	    }
	    elsif ( $k =~ /^(width|height|w|h)$/ ) {
		$img{$k} = $v;
	    }
	    elsif ( $k =~ /^(x|y)$/ ) {
		$img{$k} = $v;
	    }
	    elsif ( $k eq "border" ) {
		$img{border} = $v;
	    }
	    else {
		carp("Invalid image attribute: \"$k\"\n");
	    }
	}
	return \%img;
    };


    # Split the string on markup instructions.
 L: foreach my $a ( split( /(<.*?>)/, $string ) ) {

	# Closing markup, e.g. </b> or </span>.
	if ( $a =~ m;^<\s*/\s*(\w+)(.*)>$; ) {
	    my $k = lc $1;
	    if ( @stack ) {
		# Check if it is closing the currently pending markup.
		if ( $stack[-1][0] =~ /^<\s*$k\b/ ) {
		    # Restore.
		    ( undef,
		      $fcur, $fsiz, $fcol, $undl, $uncl, $ovrl, $ovcl,
		      $bcol, $strk, $stcl, $base, $href ) = @{$stack[-1]};
		    pop(@stack);
		}
		else {
		    carp("Markup error: \"$string\"\n",
			 "  Closing <$k> but $stack[-1][0] is open\n");
		    next;
		}
	    }
	    else {
		carp("Markup error: \"$string\"\n",
		     "  Closing <$k> but no markup is open\n");
		next;
	    }
	}

	# Opening markup, e.g. <b> or <span ...>.
	elsif ( $a =~ m;^<\s*([-\w]+)(.*)?>$; ) {
	    my $k = lc $1;
	    my $v = $2;
	    my $closed = $v =~ s;\s*/\s*$;;;

	    # Save.
	    push( @stack, [ "<$k".lc($v).">",
			    $fcur, $fsiz, $fcol, $undl, $uncl, $ovrl, $ovcl,
			    $bcol, $strk, $stcl, $base, $href ] );

	    # Find existing shortcode.
	    if ( my $sc = $self->{_sc}->{$k} // $shortcodes{$k} ) {
		$span->($sc);
	    }

	    # <strut width=".."/>
	    elsif ( $k eq "strut" && $closed ) {
		my $args = { w => 0, %{parse_kv($v)} };
		# Split the attributes.
		while ( my ( $k, $v ) = each(%$args) ) {
		    if ( $k =~ /^(w(?:idth)?|a(?:scend)?|d(?:escend)?)$/i ) {
			if ( $v =~ /^([.\d]+)em$/ ) {
			    $args->{$k} = $1 * $fsiz;
			}
			elsif ( $v =~ /^([.\d]+)ex$/ ) {
			    $args->{$k} = 0.5 * $1 * $fsiz;
			}
			else {
			    $args->{$k} = 0+$v;
			}
		    }
		    elsif ( $k =~ /^(label)$/i ) {
			$args->{$k} = $v;
		    }
		    else {
			carp("Unknown strut attribute: \"$k\"\n");
		    }
		}
		push( @content, { type	=> $k,
				  width	=> $args->{width}   // $args->{w},
				  desc	=> $args->{descend} // $args->{d},
				  asc	=> $args->{ascend}  // $args->{a},
				  $args->{label} ? ( label => $args->{label} ) : (),
				} );
	    }

	    # <span ...>.
	    elsif ( $k =~ /^(span)$/ ) {
		$span->($v);
	    }

	    # <.../>.
	    elsif ( ( my $p = $self->get_element_handler($k) ) && $closed ) {
		push( @content, { type => $k,
				  %{ $p->parse
				       ( { type			      => $k,
					   font			      => $fcur,
					   size			      => $fsiz,
					   color		      => $fcol,
					   bgcolor		      => $bcol,
					   underline		      => $undl,
					   underline_color	      => $uncl,
					   overline		      => $ovrl,
					   overline_color	      => $ovcl,
					   strikethrough	      => $strk,
					   strikethrough_color	      => $stcl,
					   base			      => $base,
					   href			      => $href,
					 }, $k, $v ) } } );
	    }

	    else {
		carp("Invalid markup: \"$k\"\n");
	    }
	    if ( $closed ) {
		$a = "</$k>";
		redo L;
	    }
	}

	# Text.
	else {
	    push( @content,
		  { type		     => "text",
		    text		     => $a,
		    font		     => $fcur,
		    size		     => $fsiz,
		    color		     => $fcol,
		    bgcolor		     => $bcol,
		    underline		     => $undl,
		    underline_color	     => $uncl,
		    overline		     => $ovrl,
		    overline_color	     => $ovcl,
		    strikethrough	     => $strk,
		    strikethrough_color	     => $stcl,
		    base		     => $base,
		    href		     => $href,
		  } ) if defined $a && $a ne '';
	}
    }

    # Verify that the markup is decently closed.
    if ( @stack ) {
	carp("Markup error: \"$string\"\n",
	     "  Unclosed markup: ",
	     join( " ", map { $_->[0] } @{[ reverse @stack ]} ), "\n" );
    }

    # Store content.
    $self->{_content} = \@content;
    delete( $self->{_bbcache} );
    delete( $self->{_struts} );
}

=over

=item set_markup_with_accel

Not supported.

=back

=cut

sub set_markup_with_accel { nyi() }

=over

=item set_attributes

=item get_attributes

Not yet implemented.

=back

=cut

sub set_attributes { nyi() }

sub get_attributes { nyi() }

=over

=item set_font_description( $description )

Sets the default font description for the layout. If no font
description is set on the layout, the font description from the
layout's context is used.

$description is a Text::Layout::FontConfig object.

=back

=cut

sub set_font_description {
    my ( $self, $description ) = @_;
    my $o = "Text::Layout::FontDescriptor";
    croak("set_font_description requires a $o object (not $description)")
      unless UNIVERSAL::isa( $description, $o );

    $self->{_currentfont}  = $description;

    if ( my $sz = $description->{size} ) {
	# Font sizes can be in either Pango units, or device units.
	# Use heuristics.
	if ( $sz > 2 * PANGO_SCALE ) { # Pango units
	    $sz /= PANGO_SCALE;
	}
	if ( $self->{_pango} ) {
	    # Pango uses 96dpi while PDF is 72dpi.
	    $sz *= PANGO_DEVICE_UNITS / PDF_DEVICE_UNITS;
	}
	$self->{_currentsize} = $sz;
    }

    $self->{_currentcolor} = $description->{color} || "black";

    delete( $self->{_bbcache} );
    delete( $self->{_struts} );
}

=over

=item get_font_description

Gets the font description for the layout.

Returns undef if no font has been set yet.

=back

=cut

sub get_font_description {
    my ( $self ) = ( @_ );
    my $res = $self->{_currentfont};
    $res->{size} = $self->get_font_size;
    return $res;
}

=over

=item set_width( $width )

Sets the width to which the lines of the layout should align,
wrap or ellipsized. A value of zero or less means unlimited width.
The width is in Pango units.

Implementation note: Only alignment is implemented.

=back

=cut

sub set_width {
    my ( $self, $width ) = @_;
    $self->{_width} = $self->{_pu2px}->($width);
    delete( $self->{_bbcache} );
    delete( $self->{_struts} );
}

=over

=item get_width

Gets the width in Pango units for for this instance, or zero if
unlimited.

=back

=cut

sub get_width {
    my ( $self ) = @_;
    $self->{_px2pu}->($self->{_width}) || 0;
}

=over

=item set_height( $height )

Sets the height in Pango units for this instance.

Implementation note: Height restrictions are not yet implemented.

=back

=cut

sub set_height {
    my ( $self, $height ) = @_;
    $self->{_height} = $self->{_pu2px}->($height);
    delete( $self->{_bbcache} );
    delete( $self->{_struts} );
}

=over

=item get_height

Gets the height in Pango units for this instance, or zero if no height
restrictions apply.

=back

=cut

sub get_height {
    my ( $self ) = @_;
    $self->{_px2pu}->($self->{_height}) || 0;
}

=over

=item set_wrap( $mode )

Sets the wrap mode; the wrap mode only has effect if a width is set on
the layout with set_width(). To turn off wrapping, set the width to
zero or less.

Not yet implemented.

=back

=cut

sub set_wrap {
    my ( $self, $mode ) = @_;
    $self->{_wrap} = $mode;
    nyi();
}

=over

=item get_wrap

Returns the current wrap mode.

Not yet implemented.

=back

=cut

sub get_wrap {
    my ( $self ) = @_;
    $self->{_wrap};
}

=over

=item is_wrapped

Queries whether the layout had to wrap any paragraphs.

=back

=cut

sub is_wrapped {
    my ( $self ) = @_;
    nyi();
}

=over

=item set_ellipsize( $mode )

Sets the type of ellipsization being performed for the layout.

Not yet implemented.

=back

=cut

sub set_ellipsize {
    my ( $self ) = @_;
    nyi();
}

=over

=item get_ellipsize

Gets the type of ellipsization being performed for the layout.

=back

=cut

sub get_ellipsize {
    my ( $self ) = @_;
    return;
}

=over

=item is_ellipsized

Queries whether the layout had to ellipsize any paragraphs.

Not yet implemented.

=back

=cut

sub is_ellipsized {
    my ( $self ) = @_;
    nyi();
}

=over

=item set_indent( $value )

Sets the width in Pango units to indent for each paragraph.

A negative value of indent will produce a hanging indentation. That
is, the first line will have the full width, and subsequent lines will
be indented by the absolute value of indent.

The indent setting is ignored if layout alignment is set to C<center>.

Not yet implemented.

=back

=cut

sub set_indent {
    my ( $self, $size ) = @_;
    $self->{_currentindent} = $self->{_pu2px}->($size);
    nyi();
}

=over

=item get_indent

Gets the current indent value in Pango units.

=back

=cut

sub get_indent {
    my ( $self ) = @_;
    $self->{_px2pu}->($self->{_currentindent}) || 0;
}

=over

=item set_spacing( $value )

Sets the amount of spacing, in Pango units, between lines of the
layout.

When placing lines with spacing, things are arranged so that

    line2.top = line1.bottom + spacing

Note: By default the line height (as determined by the font) for
placing lines is used. The spacing set with this function is only
taken into account when the line-height factor is set to zero with
set_line_spacing().

Not yet implemented.

=back

=cut

sub set_spacing {
    my ( $self, $spacing ) = @_;
    $self->{_currentspacing} = $self->{_pu2px}->($spacing);
    delete( $self->{_bbcache} );
    delete( $self->{_struts} );
}

=over

=item get_spacing

Gets the current amount of spacing, in Pango units.

=back

=cut

sub get_spacing {
    my ( $self ) = @_;
    $self->{_px2pu}->($self->{_currentspacing});
}

=over

=item set_line_spacing( $factor )

Sets a factor for line spacing. Typical values are: 0, 1, 1.5, 2. The
default value is 0.

If factor is non-zero, lines are placed so that

    baseline2 = baseline1 + factor * height2

where height2 is the line height of the second line (as determined by
the font(s)). In this case, the spacing set with set_spacing() is ignored.

If factor is zero, spacing is applied as before.

Not yet implemented.

=back

=cut

sub set_line_spacing {
    my ( $self, $factor ) = @_;
    $self->{_currentlinespacing} = $factor;
    delete( $self->{_bbcache} );
    delete( $self->{_struts} );
}

=over

=item get_line_spacing

Gets the current line spacing factor.

=back

=cut

sub get_line_spacing {
    my ( $self ) = @_;
    $self->{_currentlinespacing} || 0
;
}

=over

=item set_justify( $state )

Sets whether each complete line should be stretched to fill the entire
width of the layout. This stretching is typically done by adding
whitespace.

Not yet implemented.

=back

=cut

sub set_justify {
    my ( $self, $state ) = @_;
    $self->{_currentjustify} = !!$state;
    nyi();
}

=over

=item get_justify

Gets whether each complete line should be stretched to fill the entire
width of the layout.

=back

=cut

sub get_justify {
    my ( $self ) = @_;
    $self->{_currentjustify};
}

=over

=item set_auto_dir( $state )

=item get_auto_dir

Not supported.

=back

=cut

sub set_auto_dir { nyi() }

sub get_auto_dir { nyi() }

=over

=item set_alignment( $align )

Sets the alignment for the layout: how partial lines are positioned
within the horizontal space available.

$align must be one of C<left>, C<center>, or C<right>,

=back

=cut

sub set_alignment {
    my ( $self, $align ) = @_;
    if ( $align =~ /^(left|right|center)$/i ) {
	$self->{_alignment} = lc $align;
    }
    else {
	croak("Invalid alignment: \"$align\"");
    }
    delete( $self->{_bbcache} );
    delete( $self->{_struts} );
}

=over

=item get_alignment

Gets the alignment for this instance.

=back

=cut

sub get_align {
    my ( $self ) = @_;
    $self->{_alignment};
}

=over

=item set_tabs( $stops )

=item get_tabs

Not yet implemented.

=back

=cut

sub set_tabs { nyi() }

sub get_tabs { nyi() }

=over

=item set_single_paragraph_mode( $state )

=item get_single_paragraph_mode

Not yet implemented.

=back

=cut

sub set_single_paragraph_mode { nyi() }

sub get_single_paragraph_mode { nyi() }

=over

=item get_unknown_glyphs_count

Counts the number unknown glyphs in the layout.

Not yet implemented.

=back

=cut

sub get_unknown_glyphs_count { nyi() }

=over

=item get_log_attrs

=item get_log_attrs_readonly

Not implemented.

=back

=cut

sub get_log_attrs { nyi() }

sub get_log_attrs_readonly { nyi() }

=over

=item index_to_pos( $index )

Converts from a character index within the layout to the onscreen position
corresponding to the grapheme at that index, which is represented as
rectangle.

Not yet implemented.

=back

=cut

sub index_to_pos { nyi() }

=over

=item index_to_line_x ( $index )

Converts from a character index within the layout to line and X position.

Not yet implemented.

=back

=cut

sub index_to_line_x { nyi() }

=over

=item xy_to_index ( $x, $y )

Converts from $x,$y position to a character index within the layout.

Not yet implemented.

=back

=cut

sub xy_to_index { nyi() }

=over

=item get_extents

Computes the logical and ink extents of the layout.

Logical extents are usually what you want for positioning things.

Return value in scalar context is a hash ref with 4 values:
 C<x>, C<y>, C<width>, and C<height>
describing the logical extents of the layout.
In list context an array of two hashrefs is returned.
The first reflects the ink extents, the second the logical extents.

In the extents, C<x> will reflect the offset when text is centered or
right aligned. It will be zero for left aligned text. For right
aligned text, it will be the width of the layout.

C<y> will reflect the offset when text is centered vertically or
bottom aligned. It will be zero for top aligned text.

See also get_pixel_extents below.

Implementation note: If the PDF::API support layer cannot calculate ink,
this function returns two identical extents.

=back

=cut

sub get_extents {
    my ( $self ) = @_;
    my $need_ink = wantarray;

    my @bb = $self->get_bbox($need_ink);
    my $res = { bl    => $bb[0],
		x     => $bb[1], y      => $bb[2],
		width => $bb[3], height => $bb[4] };
    my $ink = $res;
    if ( @bb > 5 ) {
	$ink = { bl    => $bb[0],
		 x     => $bb[5], y      => $bb[6],
		 width => $bb[7], height => $bb[8] };
    }
    return $need_ink ? ( $ink, $res ) : $res;
}

=over

=item get_pixel_extents

Same as get_extents, but using device units.

The returned values are suitable for (assuming $pdf_text and
$pdf_gfx are the PDF text and graphics contexts):

    $layout->render( $x, $y, $pdf_text );
    $box = $layout->get_pixel_extents;
    $pdf_gfx->translate( $x, $y );
    $pdf_gfx->rect( @$box{ qw( x y width height ) } );
    $pdf_gfx->stroke;

=back

=cut

sub get_pixel_extents {
    my ( $self ) = @_;

    my $need_ink = wantarray;

    my @bb = $self->get_pixel_bbox($need_ink);
    my $res = { bl    => $bb[0],
		x     => $bb[1], y      => $bb[2],
		width => $bb[3], height => $bb[4] };
    my $ink = $res;
    if ( @bb > 5 ) {
	$ink = { bl    => $bb[0],
		 x     => $bb[5], y      => $bb[6],
		 width => $bb[7], height => $bb[8] };
    }
    return $need_ink ? ( $ink, $res ) : $res;
}

=over

=cut

=item get_size

Returns the width and height of this layout.

In list context, width and height are returned as an two-element list.
In scalar context a hashref with keys C<width> and C<height> is
returned.

=back

=cut

sub get_size {
    my ( $self ) = @_;
    my $e = $self->get_extents;
    wantarray
      ? return ( $e->{width}, $e->{height} )
      : return { width => $e->{width}, height => $e->{height} };
}

=over

=item get_pixel_size

Same as get_size().

=back

=cut

sub get_pixel_size {
    my ( $self ) = @_;
    my $e = $self->get_pixel_extents;
    wantarray
      ? return ( $e->{width}, $e->{height} )
      : return { width => $e->{width}, height => $e->{height} };
}

=over

=item get_iter

Returns the layout for the first line.

Implementation note: This is a dummy, it returns the layout.
It is provided so you can write $layout->get_iter()->get_baseline()
to be compatible with the official Pango API.

=back

=cut

sub get_iter { $_[0] }

=over

=item get_baseline

Gets the Y position of the baseline of the first line in this layout.

Implementation note: Position is relative to top left, so due to the
PDF coordinate system this is a negative number.

Note: The Python API only supports this method on iteration objects.
See get_iter().

=back

=cut

sub get_baseline {
    my ( $self ) = @_;
    return -$self->get_bbox->[0];
}

=head1 METHODS NOT IMPLEMENTED

=over

=item get_line_count

=item get_line( $index )

=item get_line_readonly( $index )

=item get_lines

=item get_lines_readonly

=item line_get_extents

=item line_get_pixel_entents

=item line_index_to_x

=item line_x_to_index

=item line_get_x_ranges

=item line_get_height

=item get_cursor_pos

=item move_cursor_visually

=back

=head2 ADDITIONAL METHODS

The following methods are not part of the Pango API.

=over

=item set_font_size( $size )

Sets the size for the current font.

=back

=cut

sub set_font_size {
    my ( $self, $size ) = @_;
    $self->{_currentsize} = $size;
    delete( $self->{_bbcache} );
    delete( $self->{_struts} );
}

=over

=item get_font_size

Returns the size of the current font.

=back

=cut

sub get_font_size {
    my ( $self ) = @_;
    $self->{_currentsize};
}

=over

=item get_bbox

Returns the bounding box of the text, w.r.t. the (top-left) origin.

bb = ( bl, x, y, width, height )

bb[0] = baseline distance from the top.

bb[1] = displacement from the left, nonzero for centered and right aligned text

bb[2] = displacement from the top, usually zero

bb[3] = advancewidth

bb[4] = height

Note that the bounding box will in general be equal to the font
bounding box except for the advancewidth.

NOTE: Some fonts do not include accents on capital letters in the ascend.

If an argument is supplied and true, get_bbox() will attempt to
calculate the ink extents as well, and add these as another set of 4
elements,

In list context returns the array of values, in scalar context an
array ref.

=back

=cut

sub get_pixel_bbox {
    my ( $self, $all ) = @_;
    my $res;
    if ( $self->{_bbcache}
	 && @{ $self->{_bbcache} } == ($all ? 9 : 5) ) {
	$res = $self->{_bbcache};
    }
    else {
	$res = $self->{_bbcache} = $self->bbox($all);
    }
    wantarray ? @$res : $res;
}

sub get_bbox {
    my ( $self, $all ) = @_;
    my @res = map { $self->{_px2pu}->($_) } ( $self->get_pixel_bbox($all) );
    wantarray ? @res : \@res;
}

=over

=item get_struts

Returns the list of the struts in the layout, if any.

Each element of the list is a hash, with key/value pairs for all the
attributes of the corresponding C<< <strut/> >> markup item.

Additionally, in each element there's a key C<_x> that contains the
horizontal displacement of the strut relative to the star of the layout.

In list context returns the array of values, in scalar context an
array ref.

=back

=cut

sub get_struts {
    my ( $self ) = @_;
    $self->bbox unless $self->{_struts};
    my $res = $self->{_struts};
    wantarray ? @$res : $res;
}

=over

=item align_struts( $other )

Aligns the fragments in both layouts to each other, based on the struts.

This will adjust the widths of the struts of both participants.

=back

=cut

sub align_struts {
    my ( $self, $other ) = @_;
    my @s1 = $self->get_struts;
    my @s2 = $other->get_struts;
    # warn("Struts mismatch\n") unless @s1 == @s2;

    # Accumulated displacements.
    my $dx1 = 0;
    my $dx2 = 0;

    # Process struts.
    for my $s1 ( @s1 ) {
	last unless @s2;

	my $s2 = shift(@s2);

	# Displacement.
	my $d = ( $s1->{_x} + $dx1 ) - ( $s2->{_x} + $dx2 );

	# Adjust the smaller to the larger.
	if ( $d < 0 ) {
	    $s1->{_strut}->{width} -= $d;
	    $dx1 -= $d;
	}
	elsif ( $d > 0 ) {
	    $s2->{_strut}->{width} += $d;
	    $dx2 += $d;
	}
    }
}

=over

=item spread_struts

Evenly distributes the available space over the struts, if any.

=back

=cut

sub spread_struts {
    my ( $self, $width ) = @_;
    my $w = $width || $self->get_width;
    return unless $w;
    my @s1 = $self->get_struts;
    return unless @s1;
    my $dx1 = ( $w - $self->get_pixel_size->{width} ) / @s1;

    # Process struts.
    for my $s1 ( @s1 ) {
	$s1->{_strut}->{width} += $dx1;
    }
}

=over

=item show( $x, $y, $text )

Transfers the content of this layout instance to the designated
graphics environment.

Use this instead of Pango::Cairo::show_layout().

For PDF::API2, $text must be an object created by the $page->text method.

=back

=cut

sub show {
    my ( $self, @data ) = @_;
    $self->render( @data );
}

=over

=item set_pango_mode( $enable )

Enable/disable Pango conformance mode.
See L<Pango Conformance Mode>.

Returns the internal Pango scaling factor if enabled.

=back

=cut

sub set_pango_mode {
    my ( $self, $conformant ) = @_;

    if ( $conformant ) {
	delete( $self->{_bbcache} ), delete( $self->{_struts} )
	  unless $self->{_pango};
	$self->{_px2pu} = sub { $_[0] * PANGO_SCALE };
	$self->{_pu2px} = sub { $_[0] / PANGO_SCALE };
	return $self->{_pango} = PANGO_SCALE;
    }

    delete( $self->{_bbcache} ), delete( $self->{_struts} )
      if $self->{_pango};
    $self->{_px2pu} = \&px2pu;
    $self->{_pu2px} = \&pu2px;
    return $self->{_pango} = 0;
}

# Legacy.
*set_pango_scale = \&set_pango_mode;

=over

=item get_pango

See L<Pango Conformance Mode>.

Returns the internal Pango scaling factor if conformance mode is
enabled, otherwise it returns 1 (one).

=back

=cut

sub get_pango_scale {
    my ( $self ) = @_;
    $self->{_pango} ? PANGO_SCALE : 1;
}

sub nyi {
    croak("Method \"" . (caller(1))[3] . "\" not implemented");
}

my $aliens;
sub register_element {
    my ( $self, $hd, @tags ) = @_;
    croak("Element handler for \"$tags[0]\" does not play nicely")
      unless $hd->DOES(qw(Text::Layout::ElementRole));
    for ( @tags ) {
	$aliens->{$_} = $hd;
    }
}

sub get_element_handler {
    my ( $self, $tag ) = @_;
    return unless $tag;
    $aliens->{$tag};
}

=over

=item register_shortcode( $code, $span, %flags )

Add user-defined shortcodes.
This is just a replacement of <$code> -> <span $span>.

When used as a class method, the shortcodes are accessible to all
layout instances,

Flags:

remove => 1 -- remove this shortcode

=back

=cut

sub register_shortcode {
    my ( $self, $key, $value, %flags ) = @_;

    my $ctl = ref($self) ? $self->{_sc} : \%shortcodes;
    $key = lc($key);

    if ( $flags{remove} ) {
	delete($ctl->{$key}) // croak("No such shortcode: \"$key\"");
    }
    else {
	$ctl->{$key} = $value;
    }
}

=head1 SEE ALSO

Description of the Pango Markup Language:
L<https://docs.gtk.org/Pango/pango_markup.html#pango-markup>.

Documentation of the Pango Layout class:
L<https://docs.gtk.org/Pango/class.Layout.html>.

L<PDF::API2>, L<PDF::Builder>, L<HarfBuzz::Shaper>, L<Font::TTF>.

=head1 AUTHOR

Johan Vromans, C<< <JV at CPAN dot org> >>

=head1 SUPPORT

Development of this module takes place on GitHub:
L<https://github.com/sciurius/perl-Text-Layout>.

You can find documentation for this module with the perldoc command.

  perldoc Text::Layout

Please report any bugs or feature requests using the issue tracker on
GitHub.

=head1 LICENSE

Copyright (C) 2019,2024 Johan Vromans

This module is free software. You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

1;
