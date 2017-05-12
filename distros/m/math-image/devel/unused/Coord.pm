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

package App::MathImage::Coord;
use 5.004;
use strict;
use warnings;
use POSIX 'floor';

# uncomment this to run the ### lines
#use Smart::Comments;

use vars '$VERSION';
$VERSION = 110;

sub new {
  my $class = shift;
  ### Coord new(): [@_]
  my $self = bless { x_scale => 1,
                     y_scale => 1,
                     x_origin => 0,
                     y_origin => 0,
                     @_ }, $class;
  if ($self->{'y_invert'}) {
    $self->{'y_scale'} = - $self->{'y_scale'};
  }
  return $self;
}

sub transform {
  my $self = shift;
  return unless @_;
  my ($x, $y) = @_;
  ### transform(): "$x, $y"
  ### x: $x * $self->{'x_scale'} + $self->{'x_origin'}
  ### y: $y * $self->{'y_scale'} + $self->{'y_origin'}
  return (floor (0.5 + $x * $self->{'x_scale'} + $self->{'x_origin'}),
          floor (0.5 + $y * $self->{'y_scale'} + $self->{'y_origin'}));
}
sub transform_proc {
  my ($self) = @_;
  my $x_scale = $self->{'x_scale'};
  my $y_scale = $self->{'y_scale'};
  my $x_origin = $self->{'x_origin'};
  my $y_origin = $self->{'y_origin'};
  return sub {
    return unless @_;
    return (floor (0.5 + $_[0] * $x_scale + $x_origin),
            floor (0.5 + $_[1] * $y_scale + $y_origin));
  };
}

sub untransform {
  my $self = shift;
  return unless @_;
  my ($x, $y) = @_;
  ### untransform(): "$x, $y"
  ### x: "- $self->{'x_origin'} / $self->{'x_scale'}   " . (($x - $self->{'x_origin'}) / $self->{'x_scale'})
  ### y: "- $self->{'y_origin'} / $self->{'y_scale'}   " . (($y - $self->{'y_origin'}) / $self->{'y_scale'})
  return (($x - $self->{'x_origin'}) / $self->{'x_scale'},
          ($y - $self->{'y_origin'}) / $self->{'y_scale'});
}
sub untransform_proc {
  my ($self) = @_;
  my $x_scale = $self->{'x_scale'};
  my $y_scale = $self->{'y_scale'};
  my $x_origin = $self->{'x_origin'};
  my $y_origin = $self->{'y_origin'};
  return sub {
    return unless @_;
    return (($_[0] - $x_origin) / $x_scale,
            ($_[1] - $y_origin) / $y_scale);
  };
}

1;
__END__




sub coord_object {
  my ($self) = @_;
  return ($self->{'coord_object'} ||= do {
    my $offset = int ($self->{'scale'} / 2);
    my $path_object = $self->path_object;
    my $scale = $self->{'scale'};
    my $invert = ($self->{'path'} eq 'Rows' || $self->{'path'} eq 'Columns'
                  ? -1
                  : -1);
    my $x_origin
      = (defined $self->{'x_left'} ? - $self->{'x_left'} * $scale
         : $path_object->x_negative ? int ($self->{'width'} / 2)
         : $offset);
    my $y_origin
      = (defined $self->{'y_bottom'} ? $self->{'y_bottom'} * $scale + $self->{'height'}
         : $self->y_negative ? int ($self->{'height'} / 2)
         : $invert > 0 ? $offset
         : $self->{'height'} - $self->{'scale'} + $offset);
    ### x_negative: $self->x_negative
    ### y_negative: $self->y_negative
    ### $x_origin
    ### $y_origin

    require App::MathImage::Coord;
    App::MathImage::Coord->new
        (x_origin => $x_origin,
         y_origin => $y_origin,
         x_scale  => $self->{'scale'},
         y_scale  => $self->{'scale'} * $invert);
  });
}

