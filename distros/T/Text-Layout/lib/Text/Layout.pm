#! perl

use strict;
use warnings;
use utf8;

package Text::Layout;

use Carp;

use Text::Layout::Version;

our $VERSION = $Text::Layout::Version::VERSION;

=head1 NAME

Text::Layout - Pango style markup formatting

This module will cooperate with PDF::API2, PDF::Builder, Cairo, and Pango.

=head1 SYNOPSIS

Text::Layout provides methods for Pango style text formatting. Where
possible the methods have identical names and (near) identical
behaviour as their Pango counterparts.

See L<https://developer.gnome.org/pango/stable/pango-Layout-Objects.html>.

The package uses Text::Layout::FontConfig to organize fonts by
description.

Example, using PDF::API2 integration:

    # Create a PDF document.
    my $pdf = PDF::API2->new;	# or PDF::Builder->new
    $pdf->mediabox( 595, 842 );	# A4, PDF units

    # Set up page and get the text context.
    my $page = $pdf->page;
    my $ctx  = $page->text;

    # Create a markup instance.
    my $layout = Text::Layout->new($pdf);

    $layout->set_font_description(Text::Layout::FontConfig->from_string("times 40"));
    $layout->set_markup( q{The <i><span foreground="red">quick</span> <span size="20"><b>brown</b></span></i> fox} );

    # Center text.
    $layout->set_width(595);	# width of A4 page
    $layout->set_alignment("center");

    # Render it.
    $layout->show( $x, $y, $ctx );

All PDF::API2 graphic and text methods can still be used, they won't
interfere with the layout methods.

=head1 NOTES FOR PDF::API2 USERS

=head2 Baselines

PDF::API2 renders texts using the font baseline as origin.

This module typesets text in an area of possibly limited width and
height. The origin is the top left of this area. Currently this area
contains only a single line of text. This will change in the future
when line breaking and paragraph formatting is implemented.

PDF::API2 coordinates have origin bottom left. This module produces
information with respect to top left coordinates.

=head1 IMPORTANT NOTES FOR PANGO USERS

=head2 Coordinate system

Pango, layered upon Cairo, uses a coordinate system that starts off
top left. So for western text the direction is increasing I<x> and
increasing I<y>.

PDF::API2 uses the coordinate system as defined in the PDF
specification. It starts off bottom left. For western text the
direction is increasing I<x> and B<de>creasing I<y>.

=head2 Pango coordinates

Pango uses two device coordinates units: Pango units and device units.
Pango units are 1000 (C<PANGO_SCALE>) times the device units.

Several methods have two variants, e.g. get_size() and
get_pixel_size(). The pixel-variant uses device units while the other
variant uses Pango units.

This module assumes no scaling. If you insist on multiplying all
values by PANGO_SCALE use the set_pango_scale() method to say so and
we'll divide everything back again internally.

=head2 Pango device units

Pango device units are 96dpi while PDF uses 72dpi. This module ignores
this and uses PDF units everywhere, except for font sizes. Since we
want e.g. a C<Times 20> font to be of equal size in the two systems,
it will set the PDF font size to 15.

I<DBD: Is this really a good idea?>

=cut

use constant {
    PANGO_SCALE		=> 1000,
    PANGO_DEVICE_UNITS	=>   96,
    PDF_DEVICE_UNITS	=>   72,
};

# Default is no Pango scaling.
sub px2pu { $_[0] };
sub pu2px { $_[0] };

use Text::Layout::FontConfig;

=head1 METHODS

=over

=item new( $pdf )

Creates a new layout instance.

The arguments are passed to the backend. Read its documentation.

=back

=cut

sub new {
    my ( $pkg, @data ) = @_;

    my $be = __PACKAGE__."::Markdown";

    if ( @data >= 2 && $data[0] eq "backend") {
	shift;
	$be = shift;
    }
    if ( $INC{"PDF/API2.pm"} ) {
	$be = __PACKAGE__."::PDFAPI2";
    }
    elsif ( $INC{"PDF/Builder.pm"} ) {
	$be = __PACKAGE__."::PDFBuilder";
    }
    elsif ( $INC{"Cairo.pm"} ) {
	$be = __PACKAGE__."::Cairo";
    }
    elsif ( $INC{"Pango.pm"} ) {
	$be = __PACKAGE__."::Pango";
    }
    eval "require $be" or croak($@);
    Text::Layout::FontConfig->set_loader( $be->can("load_font") );
    bless { _be      => $be,
	    _context => $be->init(@data),
	    _fonts   => {},
	    _content => [],
	    _px2pu   => \&px2pu,
	    _pu2px   => \&pu2px,
	  };
}

=over

=item copy

Copies (clones) a layout instance.

The content is copied deeply, the context and fonts are copied by
reference.

=back

=cut

sub copy {
    my ( $self, $pdf, %atts ) = @_;

    my $copy = bless { %$self } => ref($self);
    $copy->{_content} = [];
    for ( @{ $self->{_content} } ) {
	my %h;
	@h{ keys %$_ } = values %$_;
	push( @{ $copy->{_content} }, { %h } );
    }

    return $copy;
}

=over

=item get_context

Gets the context (PDF document) of this layout.

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
      [ { text  => $string,
	  font  => $self->{_currentfont},
	  size  => $self->{_currentsize},
	  color => $self->{_currentcolor},
	  base  => 0,
	} ];
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

use constant STEP => 0.8;	# TODO: Optimal value?

my %magstep =
  ( "xx-small"	=> 1.0*STEP*STEP*STEP,
    "x-small"	=> 1.0*STEP*STEP,
    "small"	=> 1.0*STEP,
    "medium"	=> 1.0,
    "large"	=> 1.0/STEP,
    "x-large"	=> 1.0/(STEP*STEP),
    "xx-large"  => 1.0/(STEP*STEP*STEP),
  );

sub set_markup {
    my ( $self, $string ) = @_;

    my @stack;
    my @content;
    my $fcur = $self->{_currentfont};
    my $fcol = $self->{_currentcolor};
    my $fsiz = $self->{_currentsize};
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
	# Split the span attributes.
	foreach my $k ( split(' ',$v) ) {

	    # key=value
	    if ( $k =~ /^([-\w]+)=(.+)$/ ) {
		my ( $k, $v ) = ( $1, $2 );

		# Strip quotes.
		$v =~ s/^(["'])(.*)\1$/$2/;

		# <span font_desc="Sans 20">
		if ( $k =~ /^(font_desc)$/ ) {
		    # NYI.
		}

		# <span face="Sans">
		elsif ( $k =~ /^(face|font_family)$/ ) {
		    $fcur = Text::Layout::FontConfig->find_font($v);
		}

		# <span size=20>
		elsif ( $k eq "size" ) {
		    if ( $try_size->($v) ) {
			#ok
		    }
		    elsif ( $v =~ /\d+(?:\.\d+)?$/ ) {
			$fsiz = 0 + $v;
		    }
		    else {
			carp("Invalid size: $v\n");
		    }
		}

		# <span style="Italic">
		elsif ( $k eq "style" ) {
		    $v = Text::Layout::FontConfig::_norm_style($v);
		    $fcur = Text::Layout::FontConfig->find_font( $fcur->{family},
					      $v, $fcur->{weight} );
		}

		# <span weight="bold">
		elsif ( $k eq "weight" ) {
		    $v = Text::Layout::FontConfig::_norm_weight($v);
		    $fcur = Text::Layout::FontConfig->find_font( $fcur->{family},
					      $fcur->{style}, $v );
		}

		# <span variant="...">
		# <span stretch="...">
		elsif ( $k =~ /^variant|stretch$/ ) {
		    # ignore for now
		}

		# <span foreground="red">
		# We allow 'color' as an alternative.
		elsif ( $k =~ /^foreground|color$/ ) {
		    $fcol = $v;
		}

		# <span background="red">
		elsif ( $k eq "background" ) {
		    # NYI.
		}

		# <span underline="double">
		elsif ( $k eq "underline" ) {
		    # NYI.
		}

		# <span rise=324>
		elsif ( $k eq "rise" ) {
		    $base += $v / 1024 * $fsiz;
		    warn("base=$base\n");
		}

		# <span strikethrough=false>
		elsif ( $k eq "strikethrough" ) {
		    # NYI.
		}

		# <span fallback=false>
		elsif ( $k eq "fallback" ) {
		    # Not supported.
		}

		# <span lang="en">
		elsif ( $k eq "lang" ) {
		    # Not supported.
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
		carp("Invalid span markup: $k\n");
	    }
	}
    };

    # Split the string on markup instructions.
    foreach my $a ( split( /(<.*?>)/, $string ) ) {

	# Closing markup, e.g. </b> or </span>.
	if ( $a =~ m;^<\s*/\s*(\w+)(.*)>$; ) {
	    my $k = lc $1;
	    if ( @stack ) {
		# Check if it is closing the currently pending markup.
		if ( $stack[-1][0] =~ /^<\s*$k\b/ ) {
		    # Restore.
		    $fcur = $stack[-1][1];
		    $fsiz = $stack[-1][2];
		    $fcol = $stack[-1][3];
		    $base = $stack[-1][4];
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
	elsif ( $a =~ m;^<\s*([-\w]+)(.*)>$; ) {
	    my $k = lc $1;
	    my $v = lc $2;
	    # Save.
	    push( @stack, [ "<$k$v>", $fcur, $fsiz, $fcol, $base ] );

	    # <b> <strong>
	    if ( $k =~ /^(b|strong)$/ ) {
		$span->("weight=bold");
	    }

	    # <big>
	    elsif ( $k eq "big" ) {
		$span->("size=larger");
	    }

	    # <i> <emp>
	    elsif ( $k =~ /^(i|emp)$/ ) {
		$span->("style=italic");
	    }

	    # <s>
	    elsif ( $k eq "s" ) {
		$span->("strikethrough=true");
	    }

	    # <sub>
	    elsif ( $k eq "sub" ) {
		$span->("size=smaller rise=300");
	    }

	    # <sup>
	    elsif ( $k eq "sup" ) {
		$span->("size=smaller rise=-300");
	    }

	    # <small>
	    elsif ( $k eq "small" ) {
		$span->("size=smaller");
	    }

	    # <tt>
	    elsif ( $k eq "tt" ) {
		$span->("face=monospace");
	    }

	    # <u>
	    elsif ( $k eq "u" ) {
		$span->("underline=single");
	    }

	    # <span ...>.
	    elsif ( $k =~ /^(span)$/ ) {
		$span->($v);
	    }

	    else {
		carp("Invalid markup: $k\n");
	    }
	}

	# Text.
	else {
	    push( @content,
		  { text  => $a,
		    font  => $fcur,
		    size  => $fsiz,
		    color => $fcol,
		    base  => $base,
		  } );
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
    $self->{_currentsize}  = $description->{size}
      if $description->{size};
    $self->{_currentcolor} = $description->{color} || "black";
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
	croak("Invalid alignment: $align");
    }
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

Return value is an array (in list context) or an array ref (in scalar
context) containing two hash refs with 4 values: C<x>, C<y>, C<width>,
and C<height>. The first reflects the ink extents, the second the
logical extents.

C<x> will reflect the offset when text is centered or right aligned.
It will be zero for left aligned text. For right aligned text, it will
be the width of the layout.

C<y> will reflect the offset when text is centered vertically or
bottom aligned. It will be zero for top aligned text.

Implementation note: Since the PDF support layer cannot calculate ink,
this function returns two identical extents.

=back

=cut

sub get_extents {
    my ( $self ) = @_;

    my @bb = @{$self->get_bbox};
    my $res = { x => $bb[0], y => 0, width => $bb[2], height => $bb[3]-$bb[1] };
    return wantarray ? ( $res, $res ) : [ $res, $res ];
}

=over

=item get_pixel_extents

Same as get_extents, but using device units.

=back

=cut

sub get_pixel_extents {
    my ( $self ) = @_;

    my @bb = @{$self->get_pixel_bbox};
    my $res = { x => $bb[0], y => 0, width => $bb[2], height => $bb[3]-$bb[1] };
    return wantarray ? ( $res, $res ) : [ $res, $res ];
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
    my $e = ($self->get_extents)[1];
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
    my $e = ($self->get_pixel_extents)[1];
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
    return -$self->get_bbox->[3];
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
}

=over

=item get_font_size

Returns the size of the current font.

NOTE: This is not a Pango API method.

=back

=cut

sub get_font_size {
    my ( $self ) = @_;
    $self->{_currentsize};
}

=over

=item get_bbox

Returns the bounding box of the text, w.r.t. the origin.

     +-----------+   ascend
     |           |
     |           |
     |           |
     |           |
     |           |
     | <-width-> |
     |           |
     |           |
     o-----------+   o = origin baseline
     |           |
     |           |
     +-----------+   descend

bb = ( left, descend, right, ascend )

bb[0] = left is nonzero for centered and right aligned text

bb[1] = descend is a negative value

bb[2] - bb[0] = advancewidth

bb[2] = layout width for right aligned text

bb[3] = ascend is a positive value

NOTE: Some fonts do not include accents on capital letters in the ascend.

=back

=cut

sub get_pixel_bbox {
    my ( $self ) = @_;
    no strict 'refs';
    my $res = "$self->{_be}::bbox"->( $self );
    wantarray ? @$res : $res;
}

sub get_bbox {
    my ( $self ) = @_;
    my @res = map { $self->{_px2pu}->($_) } ( $self->get_pixel_bbox );
    wantarray ? @res : \@res;
}

=over

=item show( $x, $y, $text )

Transfers the content of this layout instance to the designated
graphics environment.

Use this instead of Pango::Cairo::show_layout().

$text must be an object created by PDF $page->text method.

=back

=cut

sub show {
    my ( $self, @data ) = @_;
    no strict 'refs';
    "$self->{_be}::render"->( $self, @data );
}

=over

=item set_pango_scale( $scale )

Sets the pango scaling to $scale, which should be 1000.

Set to 1 to cancel scaling, causing all methods to use pixel units
instead of Pango units. Set to 0 to get the default behaviour.

=back

=cut

sub set_pango_scale {
    my ( $self, $scale ) = @_;
    $scale //= PANGO_SCALE;
    if ( $scale == 0 ) {
	$self->{_px2pu} = \&px2pu;
	$self->{_pu2px} = \&pu2px;
    }
    elsif ( $scale == 1 ) {
	$self->{_px2pu} = sub { $_[0] };
	$self->{_pu2px} = sub { $_[0] };
    }
    else {
	carp("Pango scale should be set to @{[PANGO_SCALE]} for Pango conformance")
	  unless $scale == PANGO_SCALE;
	$self->{_px2pu} = sub { $_[0] * $scale };
	$self->{_pu2px} = sub { $_[0] / $scale };
    }
}

sub get_pango_scale {
    my ( $self ) = @_;
    $self->{_px2pu}->(1);
}

sub nyi {
    croak("Method \"" . (caller(1))[3] . "\" not implemented");
}

=head1 SEE ALSO

Description of the Pango Markup Language:
L<https://developer.gnome.org/pygtk/stable/pango-markup-language.html>.

Documentation  of the Pango Layout class:
L<https://developer.gnome.org/pango/stable/pango-Layout-Objects.html>.

L<PDF::API2>, L<PDF::Builder>, L<Font::TTF>.

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

Copyright (C) 2019, Johan Vromans

This module is free software. You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

1;
