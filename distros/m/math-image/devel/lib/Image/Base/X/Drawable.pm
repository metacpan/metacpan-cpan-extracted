# no GCValues filling ...


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


package App::MathImage::Image::Base::X::Drawable;
use 5.004;
use strict;
use Carp;
use X11::Lib;
use vars '$VERSION', '@ISA';

use Image::Base;
@ISA = ('Image::Base');

$VERSION = 110;

sub new {
  my ($class, %params) = @_;
  ### X-Pixmap new: \%params

  if (exists $params{'-pixmap'}) {
    $params{'-drawable'} = delete $params{'-pixmap'};
  }
  return $class->SUPER::new (%params);
}

sub DESTROY {
  my ($self) = @_;
  if (my $gc = delete $self->{'-gc_created'}) {
    $self->{'-X'}->FreeGC ($gc);
  }
}

sub xy {
  my ($self, $x, $y, $colour) = @_;
  if (@_ == 4) {
    _gc_colour($self,$colour);
    X::DrawPoint ($self->{'-display'}, $self->{'-drawable'},
                  _gc_colour($self,$colour),
                  $x, $y);
  } else {
    die 'Pixel fetch not yet implemented';
  }
}
sub line {
  my ($self, $x0, $y0, $x1, $y1, $colour) = @_ ;
  X::DrawLine ($self->{'-display'}, $self->{'-drawable'},
               _gc_colour($self,$colour),
               $x0,$y0, $x1,$y1);
}
# sub Image_Base_Other_xy_points {
#   my $self = shift;
#   my $colour = shift;
#   X::DrawPoints ($self->{'-display'}, $self->{'-drawable'},
#                  _gc_colour($self,$colour),
#                  @_);
# }
# FIXME: fill parameter ...
sub rectangle {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  my $func = ($fill ? \&X::FillRectangle : \&X::DrawRectangle);
  &$func ($self->{'-display'},
                    $self->{'-drawable'},
                    _gc_colour($self,$colour),
                    $x1, $y1, $x2-$x1+1, $y2-$y1+1);
}
sub ellipse {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  my $func = ($fill ? \&X::FillArc : \&X::DrawArc);
  &$func ($self->{'-display'},
          $self->{'-drawable'},
          _gc_colour($self,$colour),
          $x1, $y1, $x2-$x1+1, $y2-$y1+1,
          0, 360*64);
}
sub _gc_colour {
  my ($self, $colour) = @_;
  my $gc = ($self->{'-gc'}
            ||= X::CreateGC ($self->{'-display'}, $self-{'-drawable'},
                             0, X::GCValues->new));
  if ($colour ne $self->{'_gc_colour'}) {
    ### _gc_colour change: $colour
    my $display = $self->{'-display'};
    my $pixel;
    if (! defined ($pixel = $self->{'-palette'}->{$colour})) {
      if (! $self->{'-alloc_colours'}) {
        croak "Colour not in palette: $colour";
      }
      my $screen_color = X::Color->new;
      my $exact_color = X::Color->new;
      X::AllocNamedColor ($display, $self->{'-colormap'}, $colour,
                          $screen_color, $exact_color);

      $pixel = $self->{'palette'}->{$colour} = $screen_color->pixel;
    }

    my $mask = 0; # foreground
    my $values = X::GCValues->new; #  => $pixel
    X::ChangeGC ($display, $gc, $mask, $values);
  }
  return $gc;
}

1;
