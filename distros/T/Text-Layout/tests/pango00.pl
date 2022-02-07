#! perl

use strict;

################ Subroutines ################

my $cr;
my $layout;
my $PANGO_SCALE = 1024;

sub showlayout {
    my ( $_cr, $_layout, $x, $y ) = @_;
    $cr = $_cr;
    $layout = $_layout;
    $cr->move_to( $x, $y );
    $cr->set_source_rgba( 0, 0, 0, 1 );
    Pango::Cairo::show_layout( $cr, $layout );
    my $dx = ($layout->get_size)[0]/$PANGO_SCALE;
    showbb( $x, $y );
    return $dx;
}

# Shows the bounding box of the last piece of text that was rendered.
sub showbb {
    my ( $x, $y ) = @_;

    # Show origin.
    _showloc( $x, $y );

    # Bounding box, top-left coordinates.
    my @e = $layout->get_pixel_extents;
    for ( 1, 0 ) {
	printf( "%-7s %6.2f %6.2f %6.2f %6.2f\n",
		(qw(Ink: Layout:))[$_],
		@{%{e[$_]}}{qw( x y width height )} );
    }

    # NOTE: Some fonts include natural spacing in the bounding box.
    # NOTE: Some fonts exclude accents on capitals from the bounding box.

    # Show baseline.
    $cr->save;
    $cr->set_source_rgb(1,0,1);
    $cr->set_line_width( 0.25 );
    $cr->translate( $x, $y );

    my %e = %{$e[1]};
    _line( $e{x}, $layout->get_baseline/$PANGO_SCALE, $e{width}, 0 );
    # Show BBox.
    $cr->rectangle( $e{x}, $e{y}, $e{width}, $e{height} );;
    $cr->stroke;
    %e = %{$e[0]};
    $cr->set_source_rgb(0,1,1);
    $cr->rectangle( $e{x}, $e{y}, $e{width}, $e{height} );;
    $cr->stroke;
    $cr->restore;

}

sub _showloc {
    my ( $x, $y, $d ) = @_;
    $x ||= 0; $y ||= 0; $d ||= 50;
    $cr->save;
    $cr->set_source_rgb(0,0,1);
    _line( $x-$d, $y, 2*$d, 0 );
    _line( $x, $y-$d, 0, 2*$d );
    $cr->restore;
}

sub _line {
    my ( $x, $y, $w, $h, $lw ) = @_;
    $lw ||= 0.5;
    $y = $y;
    $cr->save;
    $cr->move_to( $x, $y );
    $cr->rel_line_to( $w, $h );
    $cr->set_line_width($lw);
    $cr->stroke;
    $cr->restore;
}

1;
