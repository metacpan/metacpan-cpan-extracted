# 
# Name:        Polygon.pm
# Purpose:     Manipulate and draw polygons on wxPerl
# Author:      Hans Oesterholt-Dijkema
# Modified by:
# Created:     19-4-2004
# RCS-ID:      $Id: Polygon.pm,v 1.3 2004/04/20 08:59:36 cvs Exp $
# Copyright:   (c) 2004 Hans Oesterholt-Dijkema
# Licence:     This program is free software; you can redistribute it and/or
#              modify it under Artistic license
#
package Wx::Polygon;

use Wx qw(:everything);
use strict;

our $VERSION='0.06';

my $pi2_360=(2.0*3.1459265)/360.0;

##############################################################
# Boot the C part
##############################################################

#use Wx::PolygonCalc;
Wx::wx_boot( 'Wx::Polygon', $VERSION );

##############################################################
# Construction
##############################################################

sub new {
  my $class=shift;
  my $args = {
	      POLYGON => undef,
	      ELLIPSE => undef,
	      @_
	      };
  my $self;
  my $def=0;

  $self->{'defined'}=0;

  bless $self,$class;

  if (defined $args->{'POLYGON'}) {
    $self->{'polygon'}=$args->{'POLYGON'};
    $def=1;
  }
  if (defined $args->{'ELLIPSE'}) {
    $self->{'polygon'}=$self->generate_ellipse(@{$args->{'ELLIPSE'}});
    $def=1;
  }

  if (not $def) {
    die "You need to specify one of the possible initializations (POLYGON, ELLIPSE, etc)";
  }

  $self->{'degrees'}=0;
  $self->{'x-off'}=0;
  $self->{'y-off'}=0;
  $self->{'scale'}=1.0;
  my @save;
  for my $p (@{$self->{'polygon'}}) {
    my $s=new Wx::Point($p->x,$p->y);
    push @save,$s;
  }
  $self->{'saved'}=\@save;
  $self->{'points'}=scalar @save;

  $self->{'color'}=new Wx::Brush(new Wx::Colour(255,255,255),wxSOLID);

return $self;
}

sub copy {
  my ($self)=@_;
  my $pol=$self->{'polygon'};
  my @p;

  for my $point (@{$pol}) {
    push @p,$point;
  }

  my $npol=new Wx::Graphics( 'POLYGON' => \@p );
  $npol->recalc();
  if (defined $self->{'rgb.r'}) {
    $npol->set_color($self->{'rgb.r'},
		     $self->{'rgb.g'},
		     $self->{'rgb.b'}
		    );
  }

  return $npol;
}

sub generate_ellipse {
  my ($self,$x,$y,$w,$h)=@_;
  my $r=0;
  my $step=1;
  my $d;
  my @pol;

  for($d=0;$d<360;$d+=$step) {
    my $px=$w*cos($pi2_360*$d);
    my $py=$h*sin($pi2_360*$d);
    my $p=new Wx::Point($x+$px,$y+$py);
    push @pol,$p;
  }

return \@pol;
}

sub add_point {
  my ($self,$x,$y,$recalc)=@_;
  if (not defined $recalc) { $recalc=1; }
  my $p=new Wx::Point($x,$y);
  push @{$self->{'polygon'}},$p;
  push @{$self->{'saved'}},$p;
  $self->{'points'}+=1;
  if ($recalc) { $self->recalc(); }
}


##############################################################
# Drawing
##############################################################

sub draw {
  my ($self,$dc)=@_;
  my $xoff=$self->{'x-off'};
  my $yoff=$self->{'y-off'};

  $dc->SetBrush($self->{'color'});
  $dc->DrawPolygon($self->{'polygon'},$xoff,$yoff);
  $dc->SetBrush(wxNullBrush);
}

##############################################################
# Setting properties
##############################################################

sub scale {
  my ($self,$scale)=@_;
  $self->{'scale'}=$scale;
  $self->recalc();
}
#   for my $p (@{$self->{'saved'}}) {
#     my $np=new Wx::Point($p->x*$scale,$p->y*$scale);
#     push @n,$np;
#   }
#   $self->{'polygon'}=\@n;
# }

sub rotate {
  my ($self,$deg)=@_;

  $self->{'degrees'}=$deg;
  $self->recalc();
}

#   c_calculate($self->{'points'},$deg,$self->{'saved'},$self->{'polygon'});
#   my $C=cos($pi2_360*$deg);
#   my $S=sin($pi2_360*$deg);
#   my @n;

#   $self->{'rotate'}=$deg;

#   for my $p (@{$self->{'saved'}}) {
#     my $x=$p->x;
#     my $y=$p->y;
#     my $np=new Wx::Point($x*$C-$y*$S,$x*$S+$y*$C);
#     push @n,$np;
#   }

#   $self->{'polygon'}=\@n;
# }

sub offset {
  my ($self,$x,$y)=@_;
  $self->{'x-off'}=$x;
  $self->{'y-off'}=$y;
}


sub set_color {
  my ($self,$r,$g,$b)=@_;
  $self->{'rbg.r'}=$r;
  $self->{'rgb.g'}=$g;
  $self->{'rgb.b'}=$b;
  $self->{'color'}=new Wx::Brush(new Wx::Colour($r,$g,$b),wxSOLID);
}

##############################################################
# Calculations (the C part)
##############################################################

sub recalc {
  my $self=shift;
#  Wx::PolygonCalc::C_RotateAndScale(
  Wx::Polygon::C_RotateAndScale(
		   $self->{'points'},
		   $self->{'scale'},
		   $self->{'scale'},
		   $self->{'degrees'},
		   $self->{'saved'},
		   $self->{'polygon'}
		   );
}

sub mid {
  my ($self)=@_;
  my $midx;
  my $midy;
  my @M;

  Wx::Polygon::C_FindMid(
            $self->{'points'},
	    $self->{'polygon'},
	    $self->{'x-off'},$self->{'y-off'},
	    \@M
	    );

return @M;

#   my ($minx,$miny,$maxx,$maxy)=(30000,30000,-30000,-30000);

#   for my $p (@{$self->{'polygon'}}) {
#     if ($minx>$p->x) { $minx=$p->x; }
#     if ($maxx<$p->x) { $maxx=$p->x; }
#     if ($miny>$p->y) { $miny=$p->y; }
#     if ($maxy<$p->y) { $maxy=$p->y; }
#   }

# return ( $self->{'x-off'}+(($maxx-$minx)/2+$minx), $self->{'y-off'}+(($maxy-$miny)/2+$miny) );
}


sub in {
  my ($self,$x,$y)=@_;

#  return Wx::PolygonCalc::C_In(
  return Wx::Polygon::C_In(
              $self->{'points'},
	      $self->{'polygon'},
	      $x,$y,
	      $self->{'x-off'},$self->{'y-off'}
	      );
#   my $yes=0;

#   my $i;
#   my $j;

#   $x-=$self->{'x-off'};
#   $y-=$self->{'y-off'};

#   my $N=scalar @{$self->{'polygon'}};
#   my $pol=$self->{'polygon'};

#   for ($i=0,$j=$N-1;$i<$N;$j=$i++) {
#     my $ypi=$pol->[$i]->y;
#     my $ypj=$pol->[$j]->y;
#     my $xpi=$pol->[$i]->x;
#     my $xpj=$pol->[$j]->x;

#     if (((($ypi<=$y) and ($y<$ypj)) or
# 	 (($ypj<=$y) and ($y<$ypi))) and
# 	($x<($xpj-$xpi)*($y-$ypi)/($ypj-$ypi)+$xpi)) {
#       $yes=!$yes;
#     }
#   }

#   if ($yes) {
#     return 1;
#   }
#   else {
#     return 0;
#   }

}


1;
__END__

=head1 NAME

Wx::Polygon - Draw and manipulate polygons for wxPerl

=head1 ABSTRACT

This module provides functions for manipulating polygons
in wxPerl.

=head1 Description

=head2 C<new( POLYGON => \(Wx::Point,...) | ELLIPSE => \(x_offset,y_offset,width,heigth) ) --E<gt> Wx::Polygon>

Instantiates a new Wx::Polygon with an array of Wx::Points for a given
C<POLYGON> or an ellipse with given parameters.

=head2 C<add_point(x,y,recalc=1) --E<gt> void>

Adds a point to the polygon. If scale and rotation have
been used, rescales and rerotates the polygon after adding
the point. If C<recalc> is set to C<0>, this will not
be done, which is better when a lot of points need added.

=head2 C<recalc() --E<gt> void>

Rescales and rerotates the polygon. This method should be
used when a lot of points need to be added. Recalculation
can than be done after adding the points.

=head2 C<set_color(r,g,b) --E<gt> void>

Sets the fill color to wxSOLID with the given C<r>, C<g>
and C<b> values.

=head2 C<mid() --E<gt> (midx:integer,midy:integer)>

Calculates the middle of the polygon (not point 'z') and 
returns a list with x and y position.

=head2 C<in(x,y) --E<gt> boolean>

Calculates if (x,y) falls within the edges of the polygon.
Returns true if so. Uses algorithm of Randolph Franklin,
L<http://astronomy.swin.edu.au/~pbourke/geometry/insidepoly>.

=head2 C<draw( dc:Wx::DC ) --E<gt> void>

Draws the polygon at given offsets and with given colour(s) to
the current DC.

=head2 C<copy() --E<gt> Wx::Polygon>

Returns a copy of the object.

=head2 C<scale(scale-factor) --E<gt> void>

Scales the polygon with C<scale-factor>.

=head2 C<rotate(degrees) --E<gt> void>

Rotates the polygon by C<degrees> degrees (0-360).

=head2 C<offset(x,y) --E<gt> void>

Sets the offset for drawing. This can be used to
transpose the polygon.





=head1 AUTHOR

Hans Oesterholt-Dijkema <oesterhol@cpan.org>

=head1 COPYRIGHT & LICENSE

(c)2004 Hans Oesterholt-Dijkema. This module can be
redistributed under artistic license.

=cut




