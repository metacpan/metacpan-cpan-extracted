#! perl

use v5.26;
use warnings;
use utf8;
use Object::Pad;

class Text::Layout::PDFAPI2::ImageElement :does(Text::Layout::ElementRole);

=head1 NAME

Text::Layout::PDFAPI2::ImageElement - <img> element for PDF images

=head1 DESCRIPTION

This class implements support for an C<< <img> >> element. It can be
used to include inline images in marked-up texts.

The class provides the three mandatory methods according to the
requirements of L<Text::Layout::ElementRole>.

=over 4

=item parse

To parse the C<< <img> >> tag in marked-up text.

=item bbox

To provide the augmented bounding box for the image.

=item render

To render the image using one of the PDF::API2 compatible libraries.

=back

An additional, overridable method getimage() is provided to actually
produce the desired image object. See L</"IMAGE PRODUCER">

=head1 THE C<< <img> >> ELEMENT

    <img attributes />

Note that the C<< <img> >> element must be self-closed, i.e., end with
C<< /> >>.

The image is placed at the current location in the text and aligned on
the baseline of the text. The image dimensions contribute to the
resultant bounding box of the formatted text. See C<dx> and C<dy>
below.

All attributes are key=value pairs. The value should (but need not) be
enclosed in quotes.

Dimensional values may be a (fractional) number optionally
postfixed by C<em> or C<ex>, or a percentage.
A number indicates points.
C<em> values are multiplied by the current font size and
C<ex> values are multiplied by half the font size.

=over 4

=item C<src=>I<IMAGE>

Provides the source of the image. This can be the filename of a jpg,
png or gif image.

=item C<width=>I<NNN>

The desired width for the image.
Dimensional.
The image is scaled if necessary.

=item C<height=>I<NNN>

The desired height for the image.
Dimensional.
The image is scaled if necessary.

=item C<dx=>I<NNN>

A horizontal offset for the image, wrt. the current location in the text.
Dimensional.

=item C<dy=>I<NNN>

Same, but vertical. Positive amounts move up.

Note the direction is opposite to the Pango C<rise>.

=item C<scale=>I<NNN>

A scaling factor, to be applied I<after> width/height scaling.
The value may be expressed as a percentage.

Independent horizontal and vertical scaling can be specified as two
comma-separated scale values.

=item C<align=>I<XXX>

Align the image in the width given by C<w=>I<NNN>.

Possible alignments are C<left>, C<center>, and C<right>.

=item C<bbox=>I<N>

If true, the actual bounding box of an object is used for placement.

By default the bounding box is only used to obtain the width and height.

This attribute has no effect on image objects.

=item C<w=>I<NNN>

The advance width of the image.
Dimensional.
Default advance is the image width plus horizontal offset.
This overrides the advance and may be zero.

=item C<h=>I<NNN>

The advance height of the image.
Dimensional.
Default advance is the image height plus vertical offset.
This overrides the advance and may be zero.

=back

=head1 CONSTRUCTOR

This class is usually instantiated in a Text::Layout register_element call:

    $layout->register_element
      ( Text::Layout::PDFAPI2::ImageElement->new( pdf => $pdf ) );

=cut

use constant TYPE => "img";
use Carp;

use Text::Layout::Utils qw(parse_kv);

field $pdf  :param :accessor;

use constant DEBUG => 0;

method parse( $ctx, $k, $v ) {

    my %ctl = ( type => TYPE );

    # Split the attributes.
    my $attr = parse_kv($v);
    while ( my ( $k, $v ) = each( %$attr ) ) {

	# Ignore case unless required.
	$v = lc $v unless $k =~ /^(src)$/;

	if ( $k =~ /^(src|bbox)$/ ) {
	    $ctl{$k} = $v;
	}
	elsif ( $k eq "align" && $v =~ /^(left|right|center)$/ ) {
	    $ctl{$k} = $v;
	}
	elsif ( $k =~ /^(width|height|dx|dy|w|h)$/ ) {
	    $v = $1 * $ctx->{size}       if $v =~ /^(-?[\d.]+)em$/;
	    $v = $1 * $ctx->{size} / 2   if $v =~ /^(-?[\d.]+)ex$/;
	    $v = $1 * $ctx->{size} / 100 if $v =~ /^(-?[\d.]+)\%$/;
	    $ctl{$k} = $v;
	}
	elsif ( $k =~ /^(scale)$/ ) {
	    my @s;
	    for ( split( /,/, $v ) ) {
		$_ = $1 / 100 if /^([\d.]+)\%$/;
		push( @s, $_ );
	    }
	    push( @s, $s[0] ) unless @s > 1;
	    carp("Invalid " . TYPE . " attribute: \"$k\" (too many values)\n")
	      unless @s == 2;
	    $ctl{$k} = \@s;
	}
	else {
	    carp("Invalid " . TYPE . " attribute: \"$k\"\n");
	}
    }

    return \%ctl;
}

method render( $fragment, $gfx, $x, $y ) {

    my $b = $self->bbox($fragment);
    my @bbox = @{$b->{bbox}};
    my @bb   = @{$b->{bb}};
    my @abox = @{$b->{abox}};

    my $width  = $bb[2] - $bb[0];
    my $height = $bb[3] - $bb[1];
    my $img = $self->getimage($fragment);
    my $is_image = ref($img) =~ /::Image::/;
    my @a;

    if ( $is_image ) {
	@a = ( $x + $bb[0], $y + $bb[1], $width, $height );
	warn("IMG x=$a[0], y=$a[1], width=$a[2], height=$a[3]\n") if DEBUG;
    }
    else {
	my ( $xscale, $yscale ) = @bb[4,5];

	@a = ( $x + $bb[0],
	       $y + $bb[1] - $yscale*($bbox[1]),
	       $xscale, $yscale );
	unless ( $fragment->{bbox} ) {
	    $a[0] -= $xscale*($bbox[0]);
	}
	warn("OBJ x=${x}->$a[0], y=${y}->$a[1], width=$width, height=$height",
	     ( $xscale != 1 || $yscale != 1 )
	     ? ", scale=$xscale" : "",
	     ( $xscale != $yscale )
	     ? ",$yscale" : "", "\n") if DEBUG;
    }

    $gfx->object( $img, @a );

    if ( $fragment->{href} ) {
	my $ann = $gfx->{' apipage'}->annotation;
	my $target = $fragment->{href};

	if ( $target =~ /^#(.+)/ ) { # named destination
	    # Augmented API for apps that keep track of bookmarks.
	    my $pdf = $gfx->{' api'};
	    if ( my $c = $pdf->can("named_dest_fiddle") ) {
		$target = $pdf->$c($1);
	    }

	    $ann->link($target);
	}
	# Named destination in other PDF.
	elsif ( $target =~ /^(?!\w{3,}:)(.*)(\#.+)$/ ) {
	    $ann->pdf( $1, $2 );
	}
	# Arbitrary document.
	else {
	    $ann->uri($target);
	}
	# $ann->border( 0, 0, 1 );
	$ann->rect( $x + $bb[0], $y + $bb[1], $x + $bb[2], $y + $bb[3] );
    }

    return { abox => \@abox };
}

method bbox( $fragment ) {

    return $fragment->{_bb} if $fragment->{_bb};

    my @bbox;	# bbox of image or object
    my @bb;	# bbox after scaling/displacement, plus scale factors
    my @abox;	# advance box

    my $img = $self->getimage($fragment);
    my $is_image = ref($img) =~ /::Image::/;

    my $img_width;
    my $img_height;
    if ( $is_image ) {
	$img_width  = $img->width;
	$img_height = $img->height;
	@bbox = ( 0, 0, $img_width, $img_height );
    }
    else {
	@bbox = $img->bbox;
	@bbox[0,2] = @bbox[2,0] if $bbox[2] < $bbox[0];
	@bbox[1,3] = @bbox[3,1] if $bbox[3] < $bbox[1];
	$img_width  = $bbox[2] - $bbox[0];
	$img_height = $bbox[3] - $bbox[1];
    }

    # Target width and height.
    my $width  = $fragment->{width}  || $img_width;
    my $height = $fragment->{height} || $img_height;

    # Calculate scale factors.
    my $xscale = 1;
    if ( $width  != $img_width  ) {
	$xscale = $width  / $img_width;
    }
    my $yscale = $xscale;
    if ( $height != $img_height ) {
	$yscale = $height / $img_height;
    }

    # Apply design scale. This cannot be set via properties but it
    # intended for 3rd party plugins.
    my $ds = $fragment->{design_scale} || 1;
    if ( $ds != 1 ) {
	$_ *= $ds for $xscale, $yscale, $width, $height;
    }

    # Apply custom scale.
    my ( $sx, $sy ) = @{$fragment->{scale} // [1,1]};
    if ( $sx != 1 ) {
	$xscale *= $sx;
	$width  *= $sx;
    }
    if ( $sy != 1 ) {
	$yscale *= $sy;
	$height *= $sy;
    }

    # Displacement wrt. the origin.
    my $dx = $fragment->{dx} || 0;
    my $dy = $fragment->{dy} || 0;

    if ( !$is_image && $fragment->{bbox} ) {
	$dx += $bbox[0] * $xscale;
	$dy += $bbox[1] * $yscale;
    }

    # Use the image baseline, if any.
    if ( $fragment->{base} ) {
	$dy += ( $bbox[1] - $fragment->{base} ) * $yscale;
    }
    
    @bb = ( $dx, $dy, $width + $dx, $height + $dy, $xscale, $yscale );
    @abox = @bb;

    # Bounding box width/height.
    if ( defined $fragment->{w} ) {
	$abox[0] = 0;
	$abox[2] = $fragment->{w};
    }
    if ( defined $fragment->{a} ) {
	$abox[3] = $fragment->{a};
    }
    if ( defined $fragment->{d} ) {
	$abox[1] = $fragment->{d};
    }
    if ( $fragment->{align} ) {
	if ( $fragment->{align} eq "right" ) {
	    $bb[0] += $abox[2] - $width;
	}
	elsif ( $fragment->{align} eq "center" ) {
	    $bb[0] += ($abox[2]-$width)/2;
	}
    }

    warn( ref($img) =~ /::Image::/ ? "IMG" : "OBJ",
	  " bbox [@bbox]",
	  " bb [@bb]",
	  " abox [@abox]",
	  ( $xscale != 1 || $yscale != 1 )
	  ? " scale=$xscale" : "",
	  ( $xscale != $yscale )
	  ? ",$yscale" : "", "\n") if DEBUG;

    return $fragment->{_bb} = { bbox => \@bbox, bb => \@bb, abox => \@abox };
}

=head1 IMAGE PRODUCER

The image object is produced with a call to method getimage(), that
can be overridden in a subclass.
The method gets a hash ref as argument.
This hash contains all the attributes and may be used for cacheing purposes.

For example,

    method getimage ($fragment) {
	$fragment->{_img} //= $self->pdf->image($fragment->{src});
    }

An overridden getimage() may produce a PDF XObject instead of an image
object. An XObject is treated similar to an image object, but is
aligned according to its bounding box if attribute C<bbox> is set to a
I<true> value, i.e., not zero.

=cut

method getimage ($fragment) {
    return $fragment->{_img} if $fragment->{_img};

    my $src = $fragment->{src};

    # API suports jpg, png, gif and tiff.
    # If we have the SVGPDF module, we can do SVG images.
    if ( $src =~ /\.svg$/i ) {
	local $SIG{__WARN__} = '__IGNORE__';
	if ( eval "require SVGPDF" ) {
	    $fragment->{_img} = SVGPDF->new( pdf => $pdf )
	      ->process( $src, combine => "stacked" )->[0]->{xo};
	}
	# API will complain.
    }

    # Pass to API.
    $fragment->{_img} //= $pdf->image($src);
}

=head1 SEE ALSO

L<Text::Layout>, L<PDF::API2>, L<PDF::Builder>.

=head1 AUTHOR

Johan Vromans, C<< <JV at CPAN dot org> >>

=head1 SUPPORT

This class is part of <Text::Layout>.

Development takes place on GitHub:
L<https://github.com/sciurius/perl-Text-Layout>.

Please report any bugs or feature requests using the issue tracker for
Text::Layout on GitHub.

=head1 LICENSE

See L<Text::Layout>.

=cut

1;
