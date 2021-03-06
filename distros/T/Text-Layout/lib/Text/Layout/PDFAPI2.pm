#! perl

use strict;
use warnings;
use utf8;

package Text::Layout::PDFAPI2;

use parent 'Text::Layout';
use Carp;

my $hb;

#### API
sub new {
    my ( $pkg, @data ) = @_;
    unless ( @data == 1 && ref($data[0]) =~ /^PDF::(API2|Builder)\b/ ) {
	croak("Usage: Text::Layout::PDFAPI2->new(\$pdf)");
    }
    my $self = $pkg->SUPER::new;
    $self->{_context} = $data[0];
    $self;
}

# Creates a (singleton) HarfBuzz::Shaper object.
sub _hb_init {
    return $hb if defined $hb;
    $hb = 0;
    eval {
	require HarfBuzz::Shaper;
	$hb = HarfBuzz::Shaper->new;
    };
    return $hb;
}

# Verify if a font needs shaping, and we can do that.
sub _hb_font_check {
    my ( $f ) = @_;
    return if $f->{_hb_checked}++;
#    use DDumper; DDumper($f);
    if ( $f->get_shaping ) {
	my $fn = $f->to_string;
	if ( $f->{font}->can("fontfilename") ) {
	    if ( _hb_init() ) {
		# warn("Font $fn will use shaping.\n");
	    }
	    else {
		carp("Font $fn: Requires shaping but HarfBuzz cannot be loaded.");
	    }
	}
	else {
	    carp("Font $fn: Shaping not supported");
	}
    }
    else {
	# warn("Font ", $f->to_string, " does not need shaping.\n");
    }
}

#### API
sub render {
    my ( $self, $x, $y, $text, $fp ) = @_;

    $self->{_lastx} = $x;
    $self->{_lasty} = $y;

    my @bb = $self->get_pixel_bbox;
    my $bl = $bb[3];
    if ( $self->{_width} && $self->{_alignment} ) {
	my $w = $bb[2] - $bb[0];
	if ( $w < $self->{_width} ) {
	    if ( $self->{_alignment} eq "right" ) {
		$x += $self->{_width} - $w;
	    }
	    elsif ( $self->{_alignment} eq "center" ) {
		$x += ( $self->{_width} - $w ) / 2;
	    }
	}
    }

    $text->save;
    foreach my $fragment ( @{ $self->{_content} } ) {
	next unless length($fragment->{text});
	my $f = $fragment->{font};
	my $font = $f->get_font($self);
	unless ( $font ) {
	    $f = $self->{_currentfont};
	    $font = $f->getfont;
	}
	$text->strokecolor( $fragment->{color} );
	$text->fillcolor( $fragment->{color} );
	$text->font( $font, $fragment->{size} || $self->{_currentsize} );

	_hb_font_check($f);
	if ( $hb && $font->can("fontfilename") ) {
	    $hb->set_font( $font->fontfilename );
	    $hb->set_size( $fragment->{size} || $self->{_currentsize} );
	    $hb->set_text( $fragment->{text} );
	    my $info = $hb->shaper($fp);
	    my $y = $y - $fragment->{base} - $bl;
	    foreach my $g ( @$info ) {
		$text->translate( $x + $g->{dx}, $y - $g->{dy} );
		$text->glyph_by_CId( $g->{g} );
		$x += $g->{ax};
		$y -= $g->{ay};
	    }
	}
	else {
	    printf("%.2f %.2f \"%s\" %s\n",
		   $x, $y-$fragment->{base}-$bl,
		   $fragment->{text},
		   join(" ", $fragment->{font}->{family},
			$fragment->{font}->{style},
			$fragment->{font}->{weight},
			$fragment->{size} || $self->{_currentsize},
			$fragment->{color},
		       ),
		  ) if 0;
	    $text->translate( $x, $y-$fragment->{base}-$bl );
	    $text->text( $fragment->{text} );
	    $x += $font->width( $fragment->{text} ) * $fragment->{size};
	}
    }
    $text->restore;
}

#### API
sub bbox {
    my ( $self ) = @_;
    my ( $x, $w, $d, $a ) = (0) x 4;
    foreach ( @{ $self->{_content} } ) {
	my $f = $_->{font};
	my $font = $f->get_font($self);
	unless ( $font ) {
	    $f = $self->{_currentfont};
	    $font = $f->getfont;
	}
	my $upem = 1000;	# as delivered by PDF::API2
	my $size = $_->{size};
	my $base = $_->{base};

	_hb_font_check( $f );
	if ( $hb && $font->can("fontfilename") ) {
	    $hb->set_font( $font->fontfilename );
	    $hb->set_size($size);
	    $hb->set_text( $_->{text} );
	    my $info = $hb->shaper;
	    foreach my $g ( @$info ) {
		$w += $g->{ax};
	    }
	}
	else {
	    $w += $font->width( $_->{text} ) * $size;
	}

	my ( $d0, $a0 );
	if ( !$f->get_interline ) {
	    # Use descender/ascender.
	    # Quite accurate, although there are some fonts that do
	    # not include accents on capitals in the ascender.
	    $d0 = $font->descender * $size / $upem - $base;
	    $a0 = $font->ascender * $size / $upem - $base;
	}
	else {
	    # Use bounding box.
	    # Some (modern) fonts include spacing in the bb.
	    my @bb = map { $_ * $size / $upem } $font->fontbbox;
	    $d0 = $bb[1] - $base;
	    $a0 = $bb[3] - $base;
	}
	$d = $d0 if $d0 < $d;
	$a = $a0 if $a0 > $a;
    }

    if ( $self->{_width} && $self->{_alignment} && $w < $self->{_width} ) {
	if ( $self->{_alignment} eq "right" ) {
	    $x += $self->{_width} - $w;
	}
	elsif ( $self->{_alignment} eq "center" ) {
	    $x += ( $self->{_width} - $w ) / 2;
	}
    }

    [ $x, $d, $x+$w, $a ];
}

#### API
sub load_font {
    my ( $self, $font ) = @_;
    return $self->{cache}->{$font}
      if $self->{cache}->{$font};

    my $ff;
    if ( $font =~ /\.[ot]tf$/ ) {
	eval {
	    $ff = $self->{_context}->ttfont( $font, -dokern => 1 );
	};
    }
    else {
	eval {
	    $ff = $self->{_context}->corefont( $font, -dokern => 1 );
	};
    }

    croak( "Cannot load font: ", $font, "\n", $@ ) unless $ff;
    # warn("Loaded font: $font\n");
    $self->{font} = $ff;
    $self->{cache}->{$font} = $ff;
    return $ff;
}

################ Extensions to PDF::API2 ################

sub PDF::API2::Content::glyph_by_CId {
    my ( $self, $cid ) = @_;
    $self->add( sprintf("<%04x> Tj", $cid ) );
    $self->{' font'}->fontfile->subsetByCId($cid);
}

# HarfBuzz requires a TT/OT font. Define the fontfilename method only
# for classes that HarfBuzz can deal with.
sub PDF::API2::Resource::CIDFont::TrueType::fontfilename {
    my ( $self ) = @_;
    $self->fontfile->{' font'}->{' fname'};
}

################ Extensions to PDF::Builder ################

sub PDF::Builder::Content::glyph_by_CId {
    my ( $self, $cid ) = @_;
    $self->add( sprintf("<%04x> Tj", $cid ) );
    $self->{' font'}->fontfile->subsetByCId($cid);
}

# HarfBuzz requires a TT/OT font. Define the fontfilename method only
# for classes that HarfBuzz can deal with.
sub PDF::Builder::Resource::CIDFont::TrueType::fontfilename {
    my ( $self ) = @_;
    $self->fontfile->{' font'}->{' fname'};
}

################ For debugging/convenience ################

# Shows the bounding box of the last piece of text that was rendered.
sub showbb {
    my ( $self, $gfx, $x, $y, $col ) = @_;
    $x //= $self->{_lastx};
    $y //= $self->{_lasty};
    $col ||= "magenta";

    # Bounding box, top-left coordinates.
    my %e = %{($self->get_pixel_extents)[1]};
    # printf( "EXT: %.2f %.2f %.2f %.2f\n", @e{qw( x y width height )} );

    # NOTE: Some fonts include natural spacing in the bounding box.
    # NOTE: Some fonts exclude accents on capitals from the bounding box.

    $gfx->save;
    $gfx->translate( $x, $y );

    # Show origin.
    _showloc($gfx);

    # Show baseline.
    _line( $gfx,
	   $e{x}, -$self->get_pixel_bbox->[3],
	   $e{width}-$e{x}, 0, $col );

    # Show bounding box.
    $gfx->linewidth( 0.25 );
    $gfx->strokecolor($col);
    $e{height} = -$e{height};		# PDF coordinates
    $gfx->rectxy( $e{x}, $e{y}, $e{width}, $e{height} );;
    $gfx->stroke;
    $gfx->restore;
}

sub _showloc {
    my ( $gfx, $x, $y, $d, $col ) = @_;
    $x ||= 0; $y ||= 0; $d ||= 50; $col ||= "blue";

    _line( $gfx, $x-$d, $y, 2*$d, 0, $col );
    _line( $gfx, $x, $y-$d, 0, 2*$d, $col );
}

sub _line {
    my ( $gfx, $x, $y, $w, $h, $col ) = @_;
    $col ||= "black";

    $gfx->save;
    $gfx->move( $x, $y );
    $gfx->line( $x+$w, $y+$h );
    $gfx->linewidth(0.5);
    $gfx->strokecolor($col);
    $gfx->stroke;
    $gfx->restore;
}

1;
