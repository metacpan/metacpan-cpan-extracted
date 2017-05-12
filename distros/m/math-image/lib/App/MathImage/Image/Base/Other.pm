# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.


package App::MathImage::Image::Base::Other;
use 5.004;
use strict;

# uncomment this to run the ### lines
#use Devel::Comments;

use vars '$VERSION';
$VERSION = 110;

sub _save_to_tempfh {
  my ($image) = @_;
  require File::Temp;
  my $tempfh = File::Temp->new;
  my $old_filename = $image->get('-file');
  # Image::Xpm doesn't like -file => undef
  if (! defined $old_filename) { $old_filename = ''; }
  require Scope::Guard;
  my $guard = Scope::Guard->new (sub { $image->set (-file => $old_filename) });
  $image->save($tempfh->filename);
  return $tempfh;
}

sub save_fh {
  my ($image, $fh) = @_;
  require File::Copy;
  File::Copy->VERSION(2.14);
  my $tempfh = _save_to_tempfh ($image);
  File::Copy::copy ($tempfh->filename, $fh);
}

sub save_string {
  my ($image) = @_;
  my $tempfh = _save_to_tempfh ($image);
  return do { local $/; <$tempfh> }; # slurp
}


sub _load_from_tempfh {
  my ($image, $tempfh) = @_;
  my $old_filename = $image->get('-file');
  my $guard = Scope::Guard->new (sub { $image->set (-file => $old_filename) });
  $image->load ($tempfh->filename);
}

sub load_fh {
  my ($image, $fh) = @_;
  require File::Copy;
  File::Copy->VERSION(2.14);
  require File::Temp;
  my $tempfh = File::Temp->new;
  File::Copy::copy ($fh, $tempfh);
  return _load_from_tempfh ($image, $tempfh);
}

sub load_string {
  my ($image, $str) = @_;
  require File::Temp;
  my $tempfh = File::Temp->new;
  (print $tempfh $str
   and close $tempfh) or die;
  return _load_from_tempfh ($image, $tempfh);
}

# draw a + shape in the rectangle top-left x1,y1, bottom-right x2,y2
sub plus {
  my ($image, $x1,$y1, $x2,$y2, $colour) = @_;
  {
    my $xmid = int(($x1+$x2)/2);
    $image->line ($xmid,$y1, $xmid,$y2, $colour);
  }
  {
    my $ymid = int(($y1+$y2)/2);
    $image->line ($x1,$ymid, $x2,$ymid, $colour);
  }
}

# +------------------+
# |      |     |     |
# |      |     |     |
# |------+     +-----|
# |                  |
# |------+     +-----|
# |      |     |     |
# |      |     |     |
# +------------------+
#
sub plus_fat {
  my ($image, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
  ### assert: $x2 >= $x1
  ### assert: $y2 >= $y1

  my $w = int(($x2-$x1+1)/3);
  my $h = int(($y2-$y1+1)/3);
  if ($fill) {
    $image->rectangle ($x1+$w,$y1, $x2-$w,$y2, $colour, 1);
    $image->rectangle ($x1,$y1+$h, $x2,$y2-$h, $colour, 1);
  } else {
    my $ya = $y1 + $h;
    my $yb = $y2 - $h;
    my $xa = $x1 + $w;
    my $xb = $x2 - $w;
    foreach my $y ($y1, $y2) {
      $image->line ($xa,$y, $xb,$y, $colour);  # top,bottom
    }
    foreach my $x ($x1, $x2) {
      $image->line ($x,$ya, $x,$yb, $colour);  # left,right
    }
    foreach my $y ($ya, $yb) {
      $image->line ($x1,$y, $xa,$y, $colour);  # left horiz
      $image->line ($x2,$y, $xb,$y, $colour);  # right horiz
    }
    foreach my $x ($xa, $xb) {
      $image->line ($x,$y1, $x,$ya, $colour);  # left horiz
      $image->line ($x,$y2, $x,$yb, $colour);  # right horiz
    }
  }
}

# draw an X in the rectangle top-left x1,y1, bottom-right x2,y2
sub draw_X {
  my ($image, $x1,$y1, $x2,$y2, $colour) = @_;
  $image->line ($x1,$y1, $x2,$y2, $colour);
  $image->line ($x2,$y1, $x1,$y2, $colour);
}

# draw a Z in the rectangle top-left x1,y1, bottom-right x2,y2
sub draw_Z {
  my ($image, $x1,$y1, $x2,$y2, $colour) = @_;
  $image->line ($x1,$y1, $x2,$y1, $colour);
  $image->line ($x2,$y1, $x1,$y2, $colour);
  $image->line ($x1,$y2, $x2,$y2, $colour);
}

# draw an N in the rectangle top-left x1,y1, bottom-right x2,y2
sub draw_N {
  my ($image, $x1,$y1, $x2,$y2, $colour) = @_;
  $image->line ($x1,$y2, $x1,$y1, $colour);
  $image->line ($x1,$y1, $x2,$y2, $colour);
  $image->line ($x2,$y2, $x2,$y1, $colour);
}

# draw an L in the rectangle top-left x1,y1, bottom-right x2,y2,
# meaning simply the left and bottom edges
sub draw_L {
  my ($image, $x1,$y1, $x2,$y2, $colour) = @_;
  if ($y1 != $y2) {
    $image->line ($x1,$y1, $x1,$y2-1, $colour);  # left
  }
  $image->line ($x1,$y2, $x2,$y2, $colour);  # bottom
}

# draw a V in the rectangle top-left x1,y1, bottom-right x2,y2,
sub draw_V {
  my ($image, $x1,$y1, $x2,$y2, $colour) = @_;
  my $xc = int(($x1+$x2)/2);
  $image->line ($x1,$y1, $xc,$y2, $colour);
  if ($x1 != $x2) {
    $image->line ($xc,$y2, $x2,$y1, $colour);
  }
}

# draw a # the rectangle top-left x1,y1, bottom-right x2,y2
sub draw_hash {
  my ($image, $x1,$y1, $x2,$y2, $colour) = @_;
  { my $width23  = int(2*($x2-$x1+1) / 3);
    { my $x = $x2-$width23;
      $image->line ($x,$y1, $x,$y2, $colour);
    }
    { my $x = $x1 + $width23;
      $image->line ($x,$y1, $x,$y2, $colour);
    }
  }
  {
    my $height23 = int(2*($y2-$y1+1) / 3);
    { my $y = $y2-$height23;
      $image->line ($x1,$y, $x2,$y, $colour);
    }
    { my $y = $y1+$height23;
      $image->line ($x1,$y, $x2,$y, $colour);
    }
  }
}

# draw a / in the rectangle top-left x1,y1, bottom-right x2,y2
sub draw_slash {
  my ($image, $x1,$y1, $x2,$y2, $colour) = @_;
  $image->line ($x1,$y2, $x2,$y1, $colour);
}
# draw a \ in the rectangle top-left x1,y1, bottom-right x2,y2
sub draw_backslash {
  my ($image, $x1,$y1, $x2,$y2, $colour) = @_;
  $image->line ($x1,$y1, $x2,$y2, $colour);
}


sub xy_points {
  my ($image) = @_;
  if (my $coderef = $image->can('Image_Base_Other_xy_points')) {
    goto &$coderef;
  }
  shift;  # $image
  my $colour = shift;
  ### points: @_
  while (@_) {
    $image->xy (shift, shift, $colour);
  }
}

sub rectangles {
  my ($image) = @_;
  ### Other rectangles()
  if (my $coderef = $image->can('Image_Base_Other_rectangles')) {
    ### goto: $coderef
    goto &$coderef;
  }
  ### iterate
  shift;  # $image
  my $colour = shift;
  my $fill = shift;
  ### rectangles: @_
  while (@_) {
    $image->rectangle (shift,shift,shift,shift, $colour, $fill);
  }
}

sub unellipse {
  my ($self, $x0, $y0, $x1, $y1, $colour, $fill) = @_;

  # per the docs, x0,y0 top left, x1,y1 bottom right
  # could relax that fairly easily, if desired ...
  ### assert: $x0 <= $x1
  ### assert: $y0 <= $y1

  my ($a, $b);
  if (($a    = ( $x1 - $x0 ) / 2) <= .5
      || ($b = ( $y1 - $y0 ) / 2) <= .5) {
    # one or two pixels high or wide, treat as rectangle
    $self->rectangle ($x0, $y0, $x1, $y1, $colour );
    return;
  }
  my $aa = $a ** 2 ;
  my $bb = $b ** 2 ;
  my $ox = ($x0 + $x1) / 2;
  my $oy = ($y0 + $y1) / 2;

  my $x  = $a - int($a) ;  # 0 or 0.5
  my $y  = $b ;
  ### initial: "origin $ox,$oy  start xy $x,$y"

  if (! $fill) {
    $self->line ($x0,$y0, $x1,$y0, $colour);
    $self->line ($x0,$y1, $x1,$y1, $colour);
  }

  my $ellipse_point =
    ($fill
     ? sub {
       ### ellipse_point fill: "$x,$y"
       $self->line ($x0,    $oy-$y, $ox-$x, $oy-$y, $colour);
       $self->line ($ox+$x, $oy-$y, $x1,    $oy-$y, $colour);
       $self->line ($x0,    $oy+$y, $ox-$x, $oy+$y, $colour);
       $self->line ($ox+$x, $oy+$y, $x1,    $oy+$y, $colour);
     }
     : sub {
       ### ellipse_point xys: "$x,$y"
       $self->xy( $x0, $oy - $y, $colour ) ;
       $self->xy( $x1, $oy - $y, $colour ) ;
       $self->xy( $x0, $oy + $y, $colour ) ;
       $self->xy( $x1, $oy + $y, $colour ) ;
       $self->xy( $ox + $x, $oy + $y, $colour ) ;
       $self->xy( $ox - $x, $oy - $y, $colour ) ;
       $self->xy( $ox + $x, $oy - $y, $colour ) ;
       $self->xy( $ox - $x, $oy + $y, $colour ) ;
     });

  # Initially,
  #     d1 = E(x+1,y-1/2)
  #        = (x+1)^2*b^2 + (y-1/2)^2*a^2 - a^2*b^2
  # which for x=0,y=b is
  #        = b^2 - a^2*b + a^2/4
  # or for x=0.5,y=b
  #        = 9/4*b^2 - ...
  #
  my $d = ($x ? 2.25*$bb : $bb) - ( $aa * $b ) + ( $aa / 4 ) ;

  while( $y >= 1
         && ( $aa * ( $y - 0.5 ) ) > ( $bb * ( $x + 1 ) ) ) {

    ### assert: $d == ($x+1)**2 * $bb + ($y-.5)**2 * $aa - $aa * $bb
    if( $d < 0 ) {
      if (! $fill) {
        # unfilled draws each pixel, but filled waits until stepping
        # down "--$y" and then draws whole horizontal line
        &$ellipse_point();
      }
      $d += ( $bb * ( ( 2 * $x ) + 3 ) ) ;
      ++$x ;
    }
    else {
      &$ellipse_point();
      $d += ( ( $bb * ( (  2 * $x ) + 3 ) ) +
              ( $aa * ( ( -2 * $y ) + 2 ) ) ) ;
      ++$x ;
      --$y ;
    }
  }

  # switch to d2 = E(x+1/2,y-1) by adding E(x+1/2,y-1) - E(x+1,y-1/2)
  $d += $aa*(.75-$y) - $bb*($x+.75);
  ### assert: $d == $bb*($x+0.5)**2 + $aa*($y-1)**2 - $aa*$bb

  ### second loop at: "$x, $y"

  while( $y >= 1 ) {
    &$ellipse_point();
    if( $d < 0 ) {
      $d += ( $bb * ( (  2 * $x ) + 2 ) ) +
        ( $aa * ( ( -2 * $y ) + 3 ) ) ;
      ++$x ;
      --$y ;
    }
    else {
      $d += ( $aa * ( ( -2 * $y ) + 3 ) ) ;
      --$y ;
    }
    ### assert: $d == $bb*($x+0.5)**2 + $aa*($y-1)**2 - $aa*$bb
  }

  # loop ends with y=0 or y=0.5 according as the height is odd or even,
  # leaving one or two middle rows to draw out to x0 and x1 edges
  ### assert: $y == $b - int($b)

  if ($fill) {
    ### middle fill: "y ".($oy-$y)." to ".($oy+$y)
    $self->rectangle( $x0, $oy - $y,
                      $x0, $oy + $y,
                      $colour, 1 ) ;

    $self->rectangle( $x1, $oy - $y,
                      $x1, $oy + $y,
                      $colour, 1 ) ;
  } else {
    # middle tails from $x out to the left/right edges
    # $x can be several pixels less than $a if small height large width
    ### tail: "y=$y, left $x0 to ".($ox-$x).", right ".($ox+$x)." to $x1"
    $self->rectangle( $x0,      $oy - $y,  # left
                      $ox - $x, $oy + $y,
                      $colour, 1 ) ;
    $self->rectangle( $ox + $x, $oy - $y,  # right
                      $x1,      $oy + $y,
                      $colour, 1 ) ;

    # $self->rectangle( $x0,      $oy - $y,  # left
    #                   $ox - $x, $oy + $y,
    #                   $colour, 1 ) ;
    # $self->rectangle( $ox + $x, $oy - $y,  # right
    #                   $x1,      $oy + $y,
    #                   $colour, 1 ) ;
  }
}

sub maltese_cross {
  my ($self, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
  ### maltese_cross(): "$x1,$y1, $x2,$y2, $colour fill=".($fill||0)

  ### assert: $x2 >= $x1
  ### assert: $y2 >= $y1

  my $w = $x2 - $x1;
  my $h = $y2 - $y1;
  if ($w < 2 || $h < 2) {
    $self->rectangle ($x1,$y1, $x2,$y2, $colour, 1);
    return;
  }
  $w = int ($w / 2);
  $h = int ($h / 2);
  my $wq = $w - int($w/2);
  my $hq = $h - int($h/2);
  my $x = $wq;
  my $y = 0;   # top

  ### $w
  ### $h
  ### x1+x: $x1+$w
  ### x2-x: $x2-$w
  ### y1+y: $y1+$h
  ### y2-y: $y2-$h

  my $draw;
  if ($fill) {
    $draw = sub {
      ### draw across: "$x,$y"
      $self->line ($x1+$x,$y1+$y, $x2-$x,$y1+$y, $colour); # upper
      $self->line ($x1+$x,$y2-$y, $x2-$x,$y2-$y, $colour); # lower
    };
  } else {
    $draw = sub {
      ### draw: "$x,$y"
      $self->xy ($x1+$x,$y1+$y, $colour); # upper left
      $self->xy ($x2-$x,$y1+$y, $colour); # upper right

      $self->xy ($x1+$x,$y2-$y, $colour); # lower left
      $self->xy ($x2-$x,$y2-$y, $colour); # lower right
    };
  }

  if ($wq > $h) {
    ### shallow ...

    my $rem = int($wq/2) - $wq;
    ### $rem

    while ($x < $w) {
      ### at: "x=$x  rem=$rem"

      if (($rem += $h) >= 0) {
        &$draw();
        $y++;
        $rem -= $w;
        $x++;
      } else {
        if (! $fill) { &$draw() }
        $x++;
      }
    }

  } else {
    ### steep ...

    # when $h is odd bias towards pointier at the narrower top/bottom ends
    my $rem = int(($h-1)/2) - $h;
    ### $rem

    while ($y < $h) {
      ### $rem
      &$draw();

      if (($rem += $wq) >= 0) {
        $rem -= $h;
        $x++;
        ### x inc to: "x=$x  rem $rem"
      }
      $y++;
    }
  }

  ### final: "$x,$y"

  # middle row if $h odd, or middle two rows if $h even
  # done explicitly rather than with &$draw() so as not to draw the middle
  # row twice when $h odd
  if ($fill) {
    $self->rectangle ($x1,$y1+$h, $x2,$y2-$h, $colour, 1);
  } else {
    $self->rectangle ($x1,$y1+$h, $x1+$x,$y2-$h, $colour, 1);  # left
    $self->rectangle ($x2-$x,$y1+$h, $x2,$y2-$h, $colour, 1);  # right
  }
}


sub NOTWORKING__draw_triangle {
  my ($image, $x1,$y1, $x2,$y2, $x3,$y3, $colour, $fill) = @_;
  if ($fill) {
    if ($y2 < $y1) { ($x1,$y1, $x2,$y2) = ($x2,$y2, $x1,$y1); }
    if ($y3 < $y1) { ($x1,$y1, $x3,$y3) = ($x3,$y3, $x1,$y1); }
    if ($y2 < $y1) { ($x1,$y1, $x2,$y2) = ($x2,$y2, $x1,$y1); }
    if ($y3 < $y2) { ($x3,$y3, $x2,$y2) = ($x2,$y2, $x3,$y3); }
  } else {
    $image->line($x1,$y1, $x2,$y2);
    $image->line($x2,$y2, $x3,$y3);
    $image->line($x3,$y3, $x1,$y1);
  }
}

#           *
#          *  ***
#        +--------***-----------+      
#       *|            ***       |
#      * |               **     |
#       *|                      |
#        |                      |
#        |                      |
#        |                      |
#        |                      |
#        +----------------------+
#
sub hexrect {
  my ($self, $x1,$y1, $x2,$y2, $colour, $fill, $left) = @_;
  ### maltese_cross(): "$x1,$y1, $x2,$y2, $colour fill=".($fill||0)

  ### assert: $x2 >= $x1
  ### assert: $y2 >= $y1

  my $w = $x2 - $x1;
  my $h = $y2 - $y1;
  if ($w < 2 || $h < 2) {
    $self->rectangle ($x1,$y1, $x2,$y2, $colour, 1);
    return;
  }

  my $w6 = int($w/6);
  my $h6 = int($h/6);

  if ($fill) {
  my $h3 = int($h/3);
  my $w3 = int($w/3);
    foreach my $o (0 .. $h3) {
      $self->line(int($x1+$w/6-$w3*$o/$h3), $y1-$h6+$o,
                  int($x2-$w*2/3 + 2*$w3*$o/$h3), $y1-$h6+$o,
                  $colour);

      $self->line(int($x1+$w*2/3-$w3*$o/$h3), $y2+$h6-$o,
                  int($x2-$w/6 + 2*$w3*$o/$h3), $y2+$h6-$o,
                  $colour);
    }
    my $h23 = $h - $h3;
    foreach my $o (0 .. $h23) {
      $self->line(int($x1 - $w/6 + $w3*$o/$h23), $y1+$h6+$o,
                  int($x2 - $w/6 + $w3*$o/$h23), $y1+$h6+$o,
                  '@');
    }

  } else {
    $self->line ($x1+$w6,$y1-$h6,
                 $x2-$w6,$y1+$h6, $colour);
    $self->line ($x2-$w6,$y1+$h6,
                 $x2+$w6,$y2-$h6, $colour);
    $self->line ($x2+$w6,$y2-$h6,
                 $x2-$w6,$y2+$h6,
                 $colour);

    $self->line ($x2-$w6,$y2+$h6,
                 $x1+$w6,$y2-$h6, $colour);
    $self->line ($x1+$w6,$y2-$h6,
                 $x1-$w6,$y1+$h6,
                 $colour);
    $self->line ($x1-$w6,$y1+$h6,
                 $x1+$w6,$y1-$h6,
                 $colour);

  }
}


1;
__END__
