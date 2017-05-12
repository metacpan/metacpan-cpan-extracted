package Tk::Canvas::GradientColor;

use warnings;
use strict;
use Carp;

#=============================================================================
# $Author    : Djibril Ousmanou                                              $
# $Copyright : 2014                                                          $
# $Update    : 30/04/2014                                                    $
# $AIM       : Create gradient background color on a button in Canvas widget $
#=============================================================================

use vars qw($VERSION);
$VERSION = '1.06';

use base qw/Tk::Derived Tk::Canvas/;
use POSIX qw( ceil );

Construct Tk::Widget 'GradientColor';

my $COLOR_TAG    = 'bg_gradient_color_canvas';
my $MIN_START    = 0;
my $MIDDLE_START = 50;
my $MAX_START    = 100;
my $NBR_COLOR    = 100;
my $PERCENT      = 100;

sub Populate {
	my ( $cw, $ref_parameters ) = @_;

	$cw->SUPER::Populate($ref_parameters);
	$cw->Advertise( 'canvas' => $cw );
	$cw->Advertise( 'Canvas' => $cw );

	# remove highlightthickness if necessary
	if ( !exists $ref_parameters->{-highlightthickness} ) {
		$cw->configure( -highlightthickness => 0 );
	}

	$cw->Delegates( DEFAULT => $cw );

	$cw->{GradientColorCanvas}{activation} = 1;
	foreach my $key (qw{ Down End Home Left Next Prior Right Up }) {
		$cw->Tk::bind( 'Tk::Canvas::GradientColor', "<Key-$key>",         undef );
		$cw->Tk::bind( 'Tk::Canvas::GradientColor', "<Control-Key-$key>", undef );
	}
	$cw->Tk::bind( '<Configure>' => \&set_gradientcolor );

	return;
}

sub get_gradientcolor {
	my $cw = shift;
	return $cw->{GradientColorCanvas}{gradient};
}

sub disabled_gradientcolor {
	my $cw = shift;
	$cw->{GradientColorCanvas}{activation} = '0';
	if ( $cw->find( 'withtag', $COLOR_TAG ) ) { $cw->delete($COLOR_TAG); }
	return 1;
}

sub enabled_gradientcolor {
	my $cw = shift;
	$cw->{GradientColorCanvas}{activation} = 1;
	$cw->set_gradientcolor;
	return 1;
}

sub set_gradientcolor {
	my ( $cw, %gradient ) = @_;

	if ( $cw->{GradientColorCanvas}{activation} == 0 ) { return; }

	my $ref_gradient = $cw->_treat_parameters_bg( \%gradient );
	my $start_color  = $ref_gradient->{-start_color};
	my $end_color    = $ref_gradient->{-end_color};
	my $number_color = $ref_gradient->{-number_color} + 1;
	my $start        = $ref_gradient->{-start};
	my $end          = $ref_gradient->{-end};
	my $type         = $ref_gradient->{-type};

	my ( $red1, $green1, $blue1 ) = $cw->hex_to_rgb($start_color);
	my ( $red2, $green2, $blue2 ) = $cw->hex_to_rgb($end_color);

	my $ref_colors = $cw->_gradient_colors( $start_color, $end_color, $number_color );

	if ( $cw->find( 'withtag', $COLOR_TAG ) ) { $cw->delete($COLOR_TAG); }
	my @alltags = $cw->find('all');

	if ( $ref_gradient->{-type} eq 'linear_horizontal' ) {
		$cw->_linear_horizontal( $ref_colors, $start, $end, $number_color );
	}
	elsif ( $ref_gradient->{-type} eq 'linear_vertical' ) {
		$cw->_linear_vertical( $ref_colors, $start, $end, $number_color );
	}
	elsif ( $ref_gradient->{-type} eq 'radial' ) {
		$cw->_radial( $ref_colors, $number_color );
	}
	elsif ( $ref_gradient->{-type} eq 'losange' ) {
		$cw->_losange( $ref_colors, $number_color );
	}
	elsif ( $ref_gradient->{-type} eq 'corner_right' ) {
		$cw->_corner_to_right( $ref_colors, $number_color );
	}
	elsif ( $ref_gradient->{-type} eq 'corner_left' ) {
		$cw->_corner_to_left( $ref_colors, $number_color );
	}
	elsif ( $ref_gradient->{-type} eq 'mirror_horizontal' ) {
		$cw->_mirror_horizontal( $ref_colors, $start, $end, $number_color );
	}
	elsif ( $ref_gradient->{-type} eq 'mirror_vertical' ) {
		$cw->_mirror_vertical( $ref_colors, $start, $end, $number_color );
	}
	else {
		$cw->_linear_horizontal( $ref_colors, $start, $end, $number_color );
	}

	foreach (@alltags) {
		$cw->raise( $_, $COLOR_TAG );
	}

	return 1;
}

sub rgb_to_hex {
	my ( $cw, $red, $green, $blue ) = @_;
	my $hexcolor = sprintf '#%02X%02X%02X', $red, $green, $blue;
	return uc $hexcolor;
}

sub hex_to_rgb {
	my ( $cw, $hexcolor ) = @_;

	$hexcolor = uc $hexcolor;
	$hexcolor =~ s{^#([0-9A-F])([0-9A-F])([0-9A-F])$}{#$1$1$2$2$3$3};

	my ( $red, $green, $blue ) = ();
	if ( $hexcolor =~ m{^#(?:[0-9A-F]{2}){3}$} ) {
		$red   = hex( substr $hexcolor, 1, 2 );
		$green = hex( substr $hexcolor, 3, 2 );
		$blue  = hex( substr $hexcolor, 5, 2 );
	}
	elsif ( $hexcolor =~ m{^#} ) {
		$cw->_error_bg( "Invalid color : We need color name or #RRGGBB or #RGB \n", 1 );
	}

	# Color name (Tk work in 16 bits)
	else {
		( $red, $green, $blue ) = map { int( ( $_ / 257 ) + 0.5 ) } $cw->rgb($hexcolor);
	}

	return ( $red, $green, $blue );
}

sub _test_start_end_values {
	my ( $cw, $start, $end ) = @_;
	if ( $start < $MIN_START or $end > $MAX_START or $start > $end ) {
		$cw->_error_bg( "Bad start ($start) and end ($end) options\n"
			  . "end value must be > start value and $MIN_START <= start and end value <= $MAX_START\n" );
		return;
	}
	return 1;
}

sub _gradient_colors {
	my ( $cw, $color1, $color2, $number_color ) = @_;

	my ( $red1, $green1, $blue1 ) = $cw->hex_to_rgb($color1);
	my ( $red2, $green2, $blue2 ) = $cw->hex_to_rgb($color2);
	my @allcolors;
	for my $number ( 0 .. $number_color - 1 ) {
		my $red   = $red1 +   ( $number / $number_color ) * ( $red2 - $red1 );
		my $green = $green1 + ( $number / $number_color ) * ( $green2 - $green1 );
		my $blue  = $blue1 +  ( $number / $number_color ) * ( $blue2 - $blue1 );
		push @allcolors, $cw->rgb_to_hex( $red, $green, $blue );
	}
	push @allcolors, $cw->rgb_to_hex( $red2, $green2, $blue2 );

	return \@allcolors;
}

sub _treat_parameters_bg {
	my ( $cw, $ref_gradient ) = @_;

	if ( defined $ref_gradient and ref($ref_gradient) ne 'HASH' ) {
		$cw->_error_bg( "'Can't set -gradient to `$ref_gradient', " . "$ref_gradient' is not an hash reference\n", 1 );
	}
	my $start_color  = $ref_gradient->{-start_color};
	my $end_color    = $ref_gradient->{-end_color};
	my $number_color = $ref_gradient->{-number_color};
	my $start        = $ref_gradient->{-start};
	my $end          = $ref_gradient->{-end};
	my $type         = $ref_gradient->{-type};

	$start_color = defined $start_color ? $start_color : $cw->{GradientColorCanvas}{gradient}{-start_color};
	$end_color   = defined $end_color   ? $end_color   : $cw->{GradientColorCanvas}{gradient}{-end_color};
	$number_color =
	  defined $number_color
	  ? $number_color
	  : $cw->{GradientColorCanvas}{gradient}{-number_color};
	$start = defined $start ? $start : $cw->{GradientColorCanvas}{gradient}{-start};
	$end   = defined $end   ? $end   : $cw->{GradientColorCanvas}{gradient}{-end};
	$type  = defined $type  ? $type  : $cw->{GradientColorCanvas}{gradient}{-type};

	if ( ( defined $type ) and ( $type eq 'mirror_horizontal' or $type eq 'mirror_vertical' ) ) {
		if ( not defined $start ) { $start = $MIDDLE_START; }
		if ( not defined $end )   { $end   = $MAX_START; }
	}

	$cw->{GradientColorCanvas}{gradient}{-start_color}  = defined $start_color  ? $start_color  : '#8BC2F5';
	$cw->{GradientColorCanvas}{gradient}{-end_color}    = defined $end_color    ? $end_color    : 'white';
	$cw->{GradientColorCanvas}{gradient}{-number_color} = defined $number_color ? $number_color : $NBR_COLOR;
	$cw->{GradientColorCanvas}{gradient}{-start}        = defined $start        ? $start        : $MIN_START;
	$cw->{GradientColorCanvas}{gradient}{-end}          = defined $end          ? $end          : $MAX_START;
	$cw->{GradientColorCanvas}{gradient}{-type}         = defined $type         ? $type         : 'linear_horizontal';

	return $cw->{GradientColorCanvas}{gradient};
}

sub _error_bg {
	my ( $cw, $error_message, $croak ) = @_;

	if ( defined $croak and $croak == 1 ) {
		croak "[BE CARREFUL] : $error_message\n";
	}
	else {
		carp "[WARNING] : $error_message\n";
	}

	return;
}

sub _linear_horizontal {
	my ( $cw, $ref_colors, $start, $end, $number_color ) = @_;

	if ( !$cw->_test_start_end_values( $start, $end ) ) { return; }

	$start = $start / $PERCENT;
	$end   = $end / $PERCENT;

	my $width  = $cw->width;
	my $height = $cw->height;

	# Largeur du canvas à dégrader
	my $width_can_grad = ( $width * $end ) - ( $width * $start );

	my $width_rec = POSIX::ceil( $width_can_grad / ( $number_color + 1 ) );
	my $x1        = $start * $width;
	my $y1        = 0;
	my $x2        = $x1 + $width_rec;
	my $y2        = $height;

	# start > 0
	if ( $start > 0 ) {
		$cw->createRectangle(
			0, 0, $x1, $y2,
			-outline => $ref_colors->[0],
			-fill    => $ref_colors->[0],
			-width   => 2,
			-tags    => $COLOR_TAG,
		);
	}

	# gradient color
	foreach my $color ( @{$ref_colors} ) {
		$cw->createRectangle(
			$x1, $y1, $x2, $y2,
			-outline => $color,
			-fill    => $color,
			-width   => 0,
			-tags    => $COLOR_TAG,
		);
		$x1 = $x2;
		$x2 += $width_rec;
	}

	# end < 1
	if ( $end < 1 ) {
		$x1 = $end * $width;
		$cw->createRectangle(
			$x1, $y1, $width, $y2,
			-outline => $ref_colors->[ scalar( @{$ref_colors} - 1 ) ],
			-fill    => $ref_colors->[ scalar( @{$ref_colors} - 1 ) ],
			-width   => 0,
			-tags    => $COLOR_TAG,
		);
	}

	return 1;
}

sub _linear_vertical {
	my ( $cw, $ref_colors, $start, $end, $number_color ) = @_;

	if ( !$cw->_test_start_end_values( $start, $end ) ) { return; }

	$start = $start / $PERCENT;
	$end   = $end / $PERCENT;

	my $width  = $cw->width;
	my $height = $cw->height;

	my $height_can_grad = ( $height * $end ) - ( $height * $start );
	my $height_rec = POSIX::ceil( $height_can_grad / ( $number_color + 1 ) );
	my $x1         = 0;
	my $y1         = $start * $height;
	my $x2         = $width;
	my $y2         = $y1 + $height_rec;

	# start > 0
	if ( $start > 0 ) {
		$cw->createRectangle(
			$x1, 0, $x2, $y2,
			-outline => $ref_colors->[0],
			-fill    => $ref_colors->[0],
			-width   => 0,
			-tags    => $COLOR_TAG,
		);
	}

	# gradient color
	foreach my $color ( @{$ref_colors} ) {
		$cw->createRectangle(
			$x1, $y1, $x2, $y2,
			-outline => $color,
			-fill    => $color,
			-width   => 0,
			-tags    => $COLOR_TAG,
		);
		$y1 = $y2;
		$y2 += $height_rec;
	}

	# end < 1
	if ( $end < 1 ) {
		$cw->createRectangle(
			$x1, $y1, $x2, $height,
			-outline => $ref_colors->[ scalar( @{$ref_colors} - 1 ) ],
			-fill    => $ref_colors->[ scalar( @{$ref_colors} - 1 ) ],
			-width   => 0,
			-tags    => $COLOR_TAG,
		);
	}

	return 1;
}

sub _mirror_vertical {
	my ( $cw, $ref_colors, $start, $end, $number_color ) = @_;

	if ( !$cw->_test_start_end_values( $start, $end ) ) { return; }

	$start = $start / $PERCENT;
	$end   = $end / $PERCENT;

	my $width  = $cw->width;
	my $height = $cw->height;

	my $height_can_grad = ( $height * $end ) - ( $height * $start );
	my $height_rec = POSIX::ceil( $height_can_grad / ( $number_color + 1 ) );
	my $x1         = 0;
	my $y1         = $start * $height;
	my $x2         = $width;
	my $y2         = $y1 + $height_rec;

	# gradient color
	foreach my $color ( @{$ref_colors} ) {
		$cw->createRectangle(
			$x1, $y1, $x2, $y2,
			-outline => $color,
			-fill    => $color,
			-width   => 0,
			-tags    => $COLOR_TAG,
		);
		$y1 = $y2;
		$y2 += $height_rec;
	}

	# end < 1
	if ( $end < 1 ) {
		$cw->createRectangle(
			$x1, $y1, $x2, $height,
			-outline => $ref_colors->[ scalar( @{$ref_colors} - 1 ) ],
			-fill    => $ref_colors->[ scalar( @{$ref_colors} - 1 ) ],
			-width   => 0,
			-tags    => $COLOR_TAG,
		);
	}

	# other end (mirror)
	my $other_end = ( 2 * $start ) - $end;

	# other_end to start
	$x1 = 0;
	$y1 = ( $start * $height ) - $height_rec;
	$x2 = $width;
	$y2 = $start * $height;

	# gradient color
	foreach my $color ( @{$ref_colors} ) {
		$cw->createRectangle(
			$x1, $y1, $x2, $y2,
			-outline => $color,
			-fill    => $color,
			-width   => 0,
			-tags    => $COLOR_TAG,
		);
		$y2 = $y1;
		$y1 -= $height_rec;
		last if ( $y2 < 0 );
	}

	if ( $other_end > 0 ) {
		$y1 += $height_rec;
		$y2 += $height_rec;

		$cw->createRectangle(
			$x1, 0, $x2, $y2,
			-outline => $ref_colors->[ scalar( @{$ref_colors} - 1 ) ],
			-fill    => $ref_colors->[ scalar( @{$ref_colors} - 1 ) ],
			-width   => 0,
			-tags    => $COLOR_TAG,
		);
	}

	return 1;
}

sub _mirror_horizontal {
	my ( $cw, $ref_colors, $start, $end, $number_color ) = @_;

	if ( !$cw->_test_start_end_values( $start, $end ) ) { return; }

	$start = $start / $PERCENT;
	$end   = $end / $PERCENT;

	my $width  = $cw->width;
	my $height = $cw->height;

	my $width_can_grad = ( $width * $end ) - ( $width * $start );
	my $width_rec = POSIX::ceil( $width_can_grad / ( $number_color + 1 ) );

	# Start to end
	my $x1 = $start * $width;
	my $y1 = 0;
	my $x2 = $x1 + $width_rec;
	my $y2 = $height;

	# gradient color
	foreach my $color ( @{$ref_colors} ) {
		$cw->createRectangle(
			$x1, $y1, $x2, $y2,
			-outline => $color,
			-fill    => $color,
			-width   => 0,
			-tags    => $COLOR_TAG,
		);
		$x1 = $x2;
		$x2 += $width_rec;
	}

	# end < 1
	if ( $end < 1 ) {
		$cw->createRectangle(
			$x1, $y1, $width, $y2,
			-outline => $ref_colors->[ scalar( @{$ref_colors} - 1 ) ],
			-fill    => $ref_colors->[ scalar( @{$ref_colors} - 1 ) ],
			-width   => 0,
			-tags    => $COLOR_TAG,
		);
	}

	# other end (mirror)
	my $other_end = ( 2 * $start ) - $end;

	# other_end to start
	$x1 = ( $start * $width ) - $width_rec;
	$y1 = 0;
	$x2 = $start * $width;
	$y2 = $height;
	foreach my $color ( @{$ref_colors} ) {
		$cw->createRectangle(
			$x1, $y1, $x2, $y2,
			-outline => $color,
			-fill    => $color,
			-width   => 0,
			-tags    => $COLOR_TAG,
		);
		$x2 = $x1;
		$x1 -= $width_rec;
		last if ( $x2 < 0 );
	}
	if ( $other_end > 0 ) {
		$x1 += $width_rec;
		$x2 += $width_rec;
		$cw->createRectangle(
			0, $y1, $x1, $y2,
			-outline => $ref_colors->[ scalar( @{$ref_colors} - 1 ) ],
			-fill    => $ref_colors->[ scalar( @{$ref_colors} - 1 ) ],
			-width   => 0,
			-tags    => $COLOR_TAG,
		);
	}

	return 1;
}

sub _corner_to_right {
	my ( $cw, $ref_colors, $number_color ) = @_;

	my $width  = $cw->width;
	my $height = $cw->height;

	my $xdiff = POSIX::ceil( ( 2 * $width ) /  ( $number_color + 1 ) );
	my $ydiff = POSIX::ceil( ( 2 * $height ) / ( $number_color + 1 ) );

	my $x1 = 0;
	my $y1 = 0;
	my $x2 = $x1 + $xdiff;
	my $y2 = 0;
	my $x3 = 0;
	my $y3 = 0;
	my $x4 = 0;
	my $y4 = $y3 + $ydiff;

	# gradient color
	foreach my $color ( @{$ref_colors} ) {
		$cw->createPolygon(
			$x1, $y1, $x3, $y3, $x4, $y4, $x2, $y2,
			-outline => $color,
			-fill    => $color,
			-width   => 0,
			-tags    => $COLOR_TAG,
		);

		$x1 = $x2;
		$x2 = $x1 + $xdiff;
		$x3 = $x4;

		$y1 = $y2;
		$y3 = $y4;
		$y4 += $ydiff;
	}

	return 1;
}

sub _corner_to_left {
	my ( $cw, $ref_colors, $number_color ) = @_;

	my $width  = $cw->width;
	my $height = $cw->height;

	my $xdiff = POSIX::ceil( ( 2 * $width ) /  ( $number_color + 1 ) );
	my $ydiff = POSIX::ceil( ( 2 * $height ) / ( $number_color + 1 ) );

	my $x1 = $width - $xdiff;
	my $y1 = 0;
	my $x2 = $width;
	my $y2 = 0;
	my $x3 = $width;
	my $y3 = 0;
	my $x4 = $width;
	my $y4 = $y3 + $ydiff;

	# gradient color
	foreach my $color ( @{$ref_colors} ) {
		$cw->createPolygon(
			$x1, $y1, $x2, $y2, $x3, $y3, $x4, $y4,
			-outline => $color,
			-fill    => $color,
			-width   => 0,
			-tags    => $COLOR_TAG,
		);

		$x1 -= $xdiff;
		$x2 -= $xdiff;
		$x3 = $width;
		$y3 += $ydiff;
		$x4 = $width;
		$y4 += $ydiff;
	}

	return 1;
}

sub _radial {
	my ( $cw, $ref_colors, $number_color ) = @_;

	my $width  = $cw->width;
	my $height = $cw->height;

	if ( $number_color < 2 ) { $number_color++; }
	my $xdiff = POSIX::ceil( ( $width / 2 ) /  ( $number_color + 1 ) );
	my $ydiff = POSIX::ceil( ( $height / 2 ) / ( $number_color + 1 ) );
	my $x1    = 0;
	my $y1    = 0;
	my $x2    = $width;
	my $y2    = $height;

	$cw->createRectangle(
		$x1, $y1, $x2, $y2,
		-outline => $ref_colors->[0],
		-fill    => $ref_colors->[0],
		-width   => 0,
		-tags    => $COLOR_TAG,
	);

	# gradient color
	foreach my $color ( @{$ref_colors} ) {
		next if ( $x1 >= $x2 or $y1 >= $y2 );
		$cw->createOval(
			$x1, $y1, $x2, $y2,
			-outline => $color,
			-fill    => $color,
			-width   => 0,
			-tags    => $COLOR_TAG,
		);
		$x1 += $xdiff;
		$y1 += $ydiff;
		$x2 -= $xdiff;
		$y2 -= $ydiff;
	}

	return 1;
}

sub _losange {
	my ( $cw, $ref_colors, $number_color ) = @_;

	my $width  = $cw->width;
	my $height = $cw->height;

	if ( $number_color < 2 ) { $number_color++; }
	my $xdiff = POSIX::ceil( ( $width / 2 ) /  ( $number_color + 1 ) );
	my $ydiff = POSIX::ceil( ( $height / 2 ) / ( $number_color + 1 ) );
	my $x1    = 0;
	my $y1    = 0;
	my $x2    = $width;
	my $y2    = $height;

	$cw->createRectangle(
		$x1, $y1, $x2, $y2,
		-outline => $ref_colors->[0],
		-fill    => $ref_colors->[0],
		-width   => 0,
		-tags    => $COLOR_TAG,
	);

	$x1 = $width / 2;
	$x2 = $width;
	my $x3 = $width / 2;
	my $x4 = 0;
	$y1 = 0;
	$y2 = $height / 2;
	my $y3 = $height;
	my $y4 = $height / 2;

	# gradient color
	foreach my $color ( @{$ref_colors} ) {
		next if ( $y1 >= $y3 );
		$cw->createPolygon(
			$x1, $y1, $x2, $y2, $x3, $y3, $x4, $y4,
			-outline => $color,
			-fill    => $color,
			-width   => 0,
			-tags    => $COLOR_TAG,
		);
		$x2 -= $xdiff;
		$x4 += $xdiff;
		$y1 += $ydiff;
		$y3 -= $ydiff;
	}

	return 1;
}

1;

__END__

=head1 NAME

Tk::Canvas::GradientColor - To create a Canvas widget with background gradient color. 

=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;
  use warnings;
  
  use Tk;
  use Tk::Canvas::GradientColor;
  
  my $mw = MainWindow->new(
    -title      => 'Tk::Canvas::GradientColor',
    -background => 'white',
  );
  
  my $canvas = $mw->GradientColor(
    -width  => 400,
    -height => 400,
  )->pack(qw/ -fill both -expand 1 /);
  
  $mw->update;
  sleep 3;
  
  # Change color
  $canvas->set_gradientcolor(
    -start_color => '#000000',
    -end_color   => '#00CDFF',
  );
  
  $mw->update;
  sleep 3;
  
  # Change type
  $canvas->set_gradientcolor(
    -start       => 50,
    -end         => 100,
    -type        => 'mirror_vertical'
  );
  
  MainLoop();


=head1 DESCRIPTION

Tk::Canvas::GradientColor is an extension of the Canvas widget. It is an easy way to build a 
canvas widget with gradient background color.

=head1 STANDARD OPTIONS

B<-background>          B<-borderwidth>	      B<-closeenough>	         B<-confine>
B<-cursor>	            B<-height>	          B<-highlightbackground>	 B<-highlightcolor>
B<-highlightthickness>	B<-insertbackground>  B<-insertborderwidth>    B<-insertofftime>	
B<-insertontime>        B<-insertwidth>       B<-relief>               B<-scrollregion> 
B<-selectbackground>    B<-selectborderwidth> B<-selectforeground>     B<-takefocus> 
B<-width>               B<-xscrollcommand>    B<-xscrollincrement>     B<-yscrollcommand> 
B<-yscrollincrement>


=head1 WIDGET-SPECIFIC METHODS

The Canvas method creates a widget object. This object supports the 
configure and cget methods described in Tk::options which can be used 
to enquire and modify the options described above. 

=head2 disabled_gradientcolor

=over 4

=item I<$canvas_bg>->B<disabled_gradientcolor>

Disabled background gradient color. The canvas widget will have the background color set by I<-background> option.

  $canvas_bg->disabled_gradientcolor;  

=back

=head2 enabled_gradientcolor

=over 4

=item I<$canvas_bg>->B<enabled_gradientcolor>

Enabled background gradient color. Background gradient color is activated by default. Use this method if 
I<disabled_gradientcolor> method is called.

  $canvas_bg->enabled_gradientcolor;  

=back

=head2 get_gradientcolor

=over 4

=item I<$canvas_bg>->B<get_gradientcolor>

Return a hash reference which contains the options to create the background gradient color.

  my $ref_gradient_options = $canvas_bg->get_gradientcolor;  

=back

=head2 set_gradientcolor

=over 4

=item I<$canvas_bg>->B<set_gradientcolor>(?options)

=back

=over 8

=item *

I<-type>

8 types are available : linear_horizontal, linear_vertical, mirror_horizontal, mirror_vertical, radial, losange, corner_right and corner_left.

    -type => 'corner_left',

Default : B<linear_horizontal>

=item *

I<-start_color>

First color of gradient color.

    -start_color => 'red',

Default : B<#8BC2F5>

=item *

I<-end_color>

Last color of gradient color.

    -end_color => '#FFCD9F',

Default : B<white>

=item *

I<-start>

    -start => 50, # Must be >= 0, <= 100 and start < end

Use it for linear_horizontal and linear_vertical type. The first color starts at 'start' percent width of canvas. 
The easy way to understand is to test the example in this documentation.

Ex : width canvas = 1000px, start = 50 : the first part of canvas has the background color of start_color  
and the gradient color start at 500px.

Default : B<0> 

Use it for mirror_horizontal and mirror_vertical type. The first color starts at 'start' percent width of canvas. 
The easy way to understand is to test the example in this documentation.

Ex : width canvas = 1000px, start = 50 : the background gradient color begins at 50 percent in two directions. 

Default : B<50> 

=item *

I<-end>

    -end => 80,  # Must be >= 0, <= 100 and end > start

Use it for linear_horizontal and linear_vertical type. The last color finishes at 'end' percent width of canvas. The 
easy way to understand is to test the example in this documentation.

Default : B<100>

Use it for mirror_horizontal and mirror_vertical type. The last color finishes at 'end' percent width of canvas and opposite. 
The easy way to understand is to test the example in this documentation.

Default : B<100> 

=item *

I<-number_color>

Number of colors between first and last color to create the gradient. 

    -number_color => 200, 

Default : B<100>

=back

=head2 rgb_to_hex

=over 4

=item I<$canvas_bg>->B<rgb_to_hex>(I<$red, $green, $blue>)

Return hexa code of rgb color.

  my $color = $canvas_bg->rgb_to_hex(200, 102, 65);  # return #C86641

=back

=head2 hex_to_rgb

=over 4

=item I<$canvas_bg>->B<hex_to_rgb>(I<string>)

Return an array with red, green an blue code rgb color.

  my ( $red, $green, $blue ) = $canvas_bg->hex_to_rgb('#C86641');  # return 200, 102, 65
  my ( $red, $green, $blue ) = $canvas_bg->hex_to_rgb('gray');     # return 190, 190, 190

=back

=head1 EXAMPLES

An example to test the configuration of the widget:

  #!/usr/bin/perl
  use strict;
  use warnings;
  
  use Tk;
  use Tk::Canvas::GradientColor;
  use Tk::BrowseEntry;
  
  my $mw = MainWindow->new(
    -title      => 'gradient color with canvas',
    -background => 'snow',
  );
  
  my $canvas = $mw->GradientColor(
    -background => '#005500',
    -width      => 500,
    -height     => 500,
  )->pack(qw/ -fill both -expand 1 /);
  
  my %arg_gradient = (
    -type         => undef,
    -start_color  => '#A780C1',
    -end_color    => 'white',
    -start        => undef,
    -end          => undef,
    -number_color => undef,
  );
  
  # configure start color
  my $bouton_color1 = $canvas->Button(
    -text    => 'select color start',
    -command => sub {
      $arg_gradient{-start_color} = $canvas->chooseColor( -title => 'select color start' );
      $canvas->set_gradientcolor(%arg_gradient);
    },
  );
  
  # configure end color
  my $bouton_color2 = $canvas->Button(
    -text    => 'select color end',
    -command => sub {
      $arg_gradient{-end_color} = $canvas->chooseColor( -title => 'select color end' );
      $canvas->set_gradientcolor(%arg_gradient);
    },
  );
  
  my $type = $canvas->BrowseEntry(
    -label   => 'Type gradient color',
    -choices => [
      qw/ linear_horizontal linear_vertical mirror_horizontal mirror_vertical radial losange corner_right corner_left/
    ],
      -background => 'white',
    -state              => 'readonly',
    -disabledbackground => 'yellow',
    -browsecmd          => sub {
      my ( $widget, $selection ) = @_;
      $arg_gradient{-type} = $selection;
      $canvas->set_gradientcolor(%arg_gradient);
    },
  );
  
  my $start_num = $canvas->Scale(
    -background   => 'white',
    -label        => 'Start',
    -from         => 0,
    -to           => 100,
    -variable     => 0,
    -orient       => 'horizontal',
    -sliderlength => 10,
    -command      => sub {
      my $selection = shift;
      $arg_gradient{-start} = $selection;
      $canvas->set_gradientcolor(%arg_gradient);
    },
  );
  
  my $end_num = $canvas->Scale(
    -background   => 'white',
    -label        => 'End',
    -from         => 0,
    -to           => 100,
    -variable     => '100',
    -orient       => 'horizontal',
    -sliderlength => 10,
    -command      => sub {
      my $selection = shift;
      $arg_gradient{-end} = $selection;
      $canvas->set_gradientcolor(%arg_gradient);
    },
  );
  my $num                = 100;
  my $entry_number_color = $canvas->BrowseEntry(
    -label              => 'Number color',
    -choices            => [qw/ 2 3 4 5 10 50 100 150 200 250 300 400 500 750 1000 1500 2000 2500/],
    -state              => 'readonly',
    -disabledbackground => 'yellow',
    -background => 'white',
    -variable           => \$num,
    -browsecmd          => sub {
      my ( $widget, $selection ) = @_;
      $arg_gradient{-number_color} = $selection;
      $canvas->set_gradientcolor(%arg_gradient);
    },
  );
  
  my $disabled_gradientcolor = $canvas->Button(
    -text    => 'disabled_gradientcolor',
    -command => sub { $canvas->disabled_gradientcolor; },
  );
  my $enabled_gradientcolor = $canvas->Button(
    -text    => 'enabled_gradientcolor',
    -command => sub { $canvas->enabled_gradientcolor; },
  );
  
  $canvas->createWindow( 100, 100, -window => $bouton_color1 );
  $canvas->createWindow( 400, 100, -window => $bouton_color2 );
  $canvas->createWindow( 100, 150, -window => $start_num );
  $canvas->createWindow( 100, 200, -window => $end_num );
  $canvas->createWindow( 350, 150, -window => $entry_number_color );
  $canvas->createWindow( 350, 200, -window => $type );
  $canvas->createWindow( 100, 350, -window => $disabled_gradientcolor );
  $canvas->createWindow( 400, 350, -window => $enabled_gradientcolor );
  
  MainLoop;


=head1 AUTHOR

Djibril Ousmanou, C<< <djibel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Tk-Canvas-GradientColor at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-Canvas-GradientColor>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SEE ALSO

See L<Tk::Canvas> for details of the standard options.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tk::Canvas::GradientColor


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tk-Canvas-GradientColor>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tk-Canvas-GradientColor>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tk-Canvas-GradientColor>

=item * Search CPAN

L<http://search.cpan.org/dist/Tk-Canvas-GradientColor/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2014 Djibril Ousmanou, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
