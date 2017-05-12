package Math::Bezier::Convert;

require 5.005_62;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
    divide_cubic
    divide_quadratic
    cubic_to_quadratic
    quadratic_to_cubic
    cubic_to_lines
    quadratic_to_lines
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';

# Globals

our $APPROX_QUADRATIC_TOLERANCE = 1;
our $APPROX_LINE_TOLERANCE = 1;
our $CTRL_PT_TOLERANCE = 3;

sub divide_cubic {
    my ($p0x, $p0y, $p1x, $p1y, $p2x, $p2y, $p3x, $p3y, $sep) = @_;
    my ($p10x, $p10y, $p11x, $p11y, $p12x, $p12y, $p20x, $p20y, $p21x, $p21y, $p30x, $p30y);

    $p10x = $p0x + $sep * ($p1x - $p0x);
    $p10y = $p0y + $sep * ($p1y - $p0y);
    $p11x = $p1x + $sep * ($p2x - $p1x);
    $p11y = $p1y + $sep * ($p2y - $p1y);
    $p12x = $p2x + $sep * ($p3x - $p2x);
    $p12y = $p2y + $sep * ($p3y - $p2y);
    $p20x = $p10x+ $sep * ($p11x-$p10x);
    $p20y = $p10y+ $sep * ($p11y-$p10y);
    $p21x = $p11x+ $sep * ($p12x-$p11x);
    $p21y = $p11y+ $sep * ($p12y-$p11y);
    $p30x = $p20x+ $sep * ($p21x-$p20x);
    $p30y = $p20y+ $sep * ($p21y-$p20y);

    return ($p0x, $p0y, $p10x, $p10y, $p20x, $p20y, $p30x, $p30y, $p21x, $p21y, $p12x, $p12y, $p3x, $p3y);
}

sub divide_quadratic {
    my ($p0x, $p0y, $p1x, $p1y, $p2x, $p2y, $sep) = @_;
    my ($p10x, $p10y, $p11x, $p11y, $p20x, $p20y);

    $p10x = $p0x + $sep * ($p1x - $p0x);
    $p10y = $p0y + $sep * ($p1y - $p0y);
    $p11x = $p1x + $sep * ($p2x - $p1x);
    $p11y = $p1y + $sep * ($p2y - $p1y);
    $p20x = $p10x+ $sep * ($p11x-$p10x);
    $p20y = $p10y+ $sep * ($p11y-$p10y);

    return ($p0x, $p0y, $p10x, $p10y, $p20x, $p20y, $p11x, $p11y, $p2x, $p2y);
}

sub cubic_to_quadratic {
    my ($p0x, $p0y, @cp) = @_;
    my ($p1x, $p1y, $p2x, $p2y, $p3x, $p3y);
    my ($a1, $b1, $a2, $b2, $cx, $cy) = (undef) x 6;
    my @qp = ($p0x, $p0y);
    my @p;

    croak '$CTRL_PT_TOLERANCE must be more than 1.5 ' unless $CTRL_PT_TOLERANCE > 1.5;

CURVE:
    while (@cp and @p = ($p1x, $p1y, $p2x, $p2y, $p3x, $p3y) = splice(@cp, 0, 6)) {

	my $step = 0.5;
	my $sep = 1;
	my @qp1 = ();
	my @cp1 = ();
	my ($cp3x, $cp3y);

	while ($step > 0.0000001) {

	    my ($v01x, $v01y) = ($p1x-$p0x, $p1y-$p0y);
	    my ($v02x, $v02y) = ($p2x-$p0x, $p2y-$p0y);
	    my ($v03x, $v03y) = ($p3x-$p0x, $p3y-$p0y);
	    my ($v32x, $v32y) = ($p2x-$p3x, $p2y-$p3y);

	    next CURVE if (abs($v01x)<0.0001 and abs($v02x)<0.0001 and abs($v03x)<0.0001 and
			   abs($v01y)<0.0001 and abs($v02y)<0.0001 and abs($v03y)<0.0001);


	    if (abs($v01x)<0.0001 and abs($v32x)<0.0001 and
		abs($v01y)<0.0001 and abs($v32y)<0.0001) {

		@qp1 = (($p0x+$p3x)/2, ($p0y+$p3y)/2);
		last;
	    }	    

	    my $n = $v01y*$v32x - $v01x*$v32y;
	    if ($n == 0) {
		if ($v02x*$v32y - $v02y*$v32x == 0) {
		    @qp1 = (($p0x+$p3x)/2, ($p0y+$p3y)/2);
		    last;
		} else {
		    $sep -= $step;
		    $step /= 2;
		    next;
		}
	    }
	    my $m1 = $v01x*$v03y - $v01y*$v03x;
	    my $m2 = $v02x*$v03y - $v03x*$v02y;
	    if ($m1/$n < 1 or $m2/$n < 1 or $m1/$n >$CTRL_PT_TOLERANCE or $m2/$n > $CTRL_PT_TOLERANCE) {
		$sep -= $step;
		$step /= 2;
		next;
	    }
	    $cx = $p0x + $m2 * $v01x / $n;
	    $cy = $p0y + $m2 * $v01y / $n;
	
	    if (defined $cx and _q_c_check($p0x, $p0y, $p1x, $p1y, $p2x, $p2y, $p3x, $p3y, $cx, $cy)) {
		@qp1 = ($cx, $cy);
		last if $sep>=1;
		$sep += $step;
	    } else {
		$sep -= $step;
	    }
	    $step /= 2;
	} continue {
	    (undef, undef, $p1x, $p1y, $p2x, $p2y, $p3x, $p3y, @cp1) = divide_cubic($p0x, $p0y, @p, $sep);
	}
	unless (@qp1) {
	    die "Can't approx @p";
#	    return @qp;
	}
	push @qp, @qp1, $p3x, $p3y;
	$p0x = $p3x;
	$p0y = $p3y;
	if (@cp1) {
	    @p = ($p1x, $p1y, $p2x, $p2y, $p3x, $p3y) = @cp1;
	    redo;
	}
    }
    return @qp;
}

sub _q_c_check {
    my ($cx0, $cy0, $cx1, $cy1, $cx2, $cy2, $cx3, $cy3, $qx1, $qy1) = @_;
    my ($a, $b, $c, $d, $sep);

    $a = (($cx0-$cx3)*($cy1-$cy3)-($cy0-$cy3)*($cx1-$cx3)<=>0);
    $b = (($cx0-$cx3)*($cy2-$cy3)-($cy0-$cy3)*($cx2-$cx3)<=>0);
    return if ($a == 0 or $b == 0 or $a != $b);

    my ($cx, $cy) = (divide_cubic($cx0,$cy0,$cx1,$cy1,$cx2,$cy2,$cx3,$cy3, 0.5))[6,7];
    $a = $cx0-2*$qx1+$cx3;
    $b = 2*$qx1-2*$cx0;
    $c = $cx0-$cx;
    $d = $b*$b-4*$a*$c;
    return if ($d<0);
    my ($qx, $qy);
    if ($a!=0) {
	$sep = (-$b-sqrt($d))/2/$a;
	$sep = (-$b+sqrt($d))/2/$a if ($sep<=0 or $sep>=1);
	return if ($sep<=0 or $sep>=1);
	($qx, $qy) = (divide_quadratic($cx0,$cy0,$qx1,$qy1,$cx3,$cy3, $sep))[4, 5];
    } else {
	($qx, $qy) = ($qx1, $qy1);
    }
    return ($cx-$qx)*($cx-$qx)+($cy-$qy)*($cy-$qy) < $APPROX_QUADRATIC_TOLERANCE;
}

sub quadratic_to_cubic {
    my ($p0x, $p0y, @qp) = @_;
    my @cp = ($p0x, $p0y);
    my ($p1x, $p1y, $p2x, $p2y);

    while (@qp and ($p1x, $p1y, $p2x, $p2y) = splice(@qp, 0, 4)) {
	push @cp, $p0x+($p1x-$p0x)*2/3, $p0y+($p1y-$p0y)*2/3, $p1x+($p2x-$p1x)/3, $p1y+($p2y-$p1y)/3, $p2x, $p2y;
	$p0x = $p2x;
	$p0y = $p2y;
    }
    return @cp;
}

sub cubic_to_lines {
    my @cp = @_;
    my @p;
    my @last = splice(@cp, 0, 2);
    my @lp = @last;

    while (@cp and @p = splice(@cp, 0, 6)) {
	push @lp, _c2lsub(@last, @p);
	push @lp, @last = @p[4,5];
    }
    return @lp;
}

sub _c2lsub {
    my @p = @_;
    my ($p0x, $p0y, $p10x, $p10y, $p20x, $p20y, $p30x, $p30y, $p21x, $p21y, $p12x, $p12y, $p3x, $p3y) =
	divide_cubic(@p[0..7], 0.5);
    my ($cx, $cy) = (($p0x+$p3x)/2, ($p0y+$p3y)/2);
    return () if (($p30x-$cx)*($p30x-$cx)+($p30y-$cy)*($p30y-$cy) < $APPROX_LINE_TOLERANCE);
    return (_c2lsub($p0x, $p0y, $p10x, $p10y, $p20x, $p20y, $p30x, $p30y), $p30x, $p30y, _c2lsub($p30x, $p30y, $p21x, $p21y, $p12x, $p12y, $p3x, $p3y));
}

sub quadratic_to_lines {
    my @qp = @_;
    my @p;
    my @last = splice(@qp, 0, 2);
    my @lp = @last;

    while (@qp and @p = splice(@qp, 0, 4)) {
	push @lp, _q2lsub(@last, @p);
	push @lp, @last = @p[2,3];
    }
    return @lp;
}

sub _q2lsub {
    my @p = @_;
    my ($p0x, $p0y, $p10x, $p10y, $p20x, $p20y, $p11x, $p11y, $p2x, $p2y) =
	divide_quadratic(@p[0..5], 0.5);
    my ($cx, $cy) = (($p0x+$p2x)/2, ($p0y+$p2y)/2);
    return () if (($p20x-$cx)*($p20x-$cx)+($p20y-$cy)*($p20y-$cy) < $APPROX_LINE_TOLERANCE);
    return (_q2lsub($p0x, $p0y, $p10x, $p10y, $p20x, $p20y), $p20x, $p20y, _q2lsub($p20x, $p20y, $p11x, $p11y, $p2x, $p2y));
}

1;
__END__

=head1 NAME

Math::Bezier::Convert - Convert cubic and quadratic bezier each other.

=head1 SYNOPSIS

  use Math::Bezier::Convert;

  @new_cubic = divide_cubic($cx1, $cy1, $cx2, $cy2, $cx3, $cy3, $cx4, $cy4, $t);
  @new_quad  = divide_quadratic($cx1, $cy1, $cx2, $cy2, $cx3, $cy3, $t);
  @quad = cubic_to_quadratic(@cubic);
  @cubic = quadratic_to_cubic(@quad);
  @lines = cubic_to_lines(@cubic);
  @lines = quadratic_to_lines(@cubic);

=head1 DESCRIPTION

Math::Bezier::Convert provides functions to convert quadratic bezier to cubic, 
to approximate cubic bezier to quadratic, and to approximate cubic and quadratic 
bezier to polyline.

Each function takes an array of the coordinates of control points of the bezier curve.
Cubic bezier consists of one I<ANCHOR> control point, two I<DIRECTOR> control points, one I<ANCHOR>, two I<DIRECTORS>, ... and the last I<ANCHOR>. 
Quadratic bezier consists of one I<ANCHOR>, one I<DIRECTOR>, ... and the last I<ANCHOR>.
The curve pass over the I<ANCHOR> point, but dose not the I<DIRECTOR> point.  
Each point consists of X and Y coordinates.  Both are flatly listed in the 
array of the curve, like ($x1, $y1, $x2, $y2, ...).

=over 4

=item divide_cubic( $cx1, $cy1, $cx2, $cy2, $cx3, $cy3, $cx4, $cy4, $t )

divides one segment of the cubic bezier curve at ratio $t, and returns 
new cubic bezier which has two segment (7 points).

=item divide_quadratic( $cx1, $cy1, $cx2, $cy2, $cx3, $cy3, $t )

divides one segment of the quadratic bezier curve at ratio $t, and returns 
new quadratic bezier which has two segment (5 points).

=item cubic_to_quadratic( @cubic )

approximates cubic bezier to quadratic bezier, and returns an array of the 
control points of the quadratic bezier curve.

=item quadratic_to_cubic( @quadratic )

converts quadratic bezier to cubic bezier, and returns an array of the 
control points of the cubic bezier curve.

=item cubic_to_lines( @cubic )

approximates cubic bezier to polyline, and returns an array of endpoints.

=item quadratic_to_lines( @cubic )

approximates quadratic bezier to polyline, and returns an array of endpoints.

=back

=head2 GLOBALS

=over 4

=item $Math::Bezier::Convert::APPROX_QUADRATIC_TOLERANCE

=item $Math::Bezier::Convert::APPROX_LINE_TOLERANCE

Tolerance of the distance between the half point of the cubic bezier and the approximation point.
Default is 1.

=item $Math::Bezier::Convert::CTRL_PT_TOLERANCE

Tolerance of the I<ANCHOR-DIRECTOR> distance ratio of quadratic to cubic.
Default is 3.  It must be specified more than 1.5.

=back

=head2 EXPORT

None by default.
All functions described above are exported when ':all' tag is specified.
All global variables are not exported in any case.

=head1 COPYRIGHT

Copyright 2000 Yasuhiro Sasama (ySas), <ysas@nmt.ne.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut

