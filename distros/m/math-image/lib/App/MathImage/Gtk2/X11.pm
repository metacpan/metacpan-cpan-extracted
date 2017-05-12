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


package App::MathImage::Gtk2::X11;
use 5.008;
use strict;
use warnings;
use Carp;
use Glib 1.220;
use Gtk2 1.220;
use Scalar::Util;
use List::Util 'min', 'max';
use X11::Protocol;
use App::MathImage::X11::Generator;

use Glib::Ex::SourceIds;

# uncomment this to run the ### lines
#use Smart::Comments '###';


our $VERSION = 110;

sub new {
  my ($class, %self) = @_;
  ### Gtk2-X11 new() ...

  my $self = bless \%self, $class;

  my $gdk_window = $self{'gdk_window'};
  my $x11_window = $self->{'x11_window'} = $gdk_window->XID;
  my $display_name = ($gdk_window->can('get_display')
                      ? $gdk_window->get_display->get_name  # gtk 2.2 up
                      : Gtk2::Gdk->get_display);        # gtk 2.0.x

  my $X = $self->{'X'} = X11::Protocol->new ($display_name);
  my $colormap = $X->{'default_colormap'};

  Scalar::Util::weaken (my $weak_self = $self);
  $self->{'io_watch'} = Glib::Ex::SourceIds->new
    (Glib::IO->add_watch (fileno($X->{'connection'}->fh),
                          ['in', 'hup', 'err'],
                          \&_do_read,
                          \$weak_self,
                          Gtk2::GTK_PRIORITY_RESIZE() + 10));
  ### X fileno: fileno($X->{'connection'}->fh)

  my ($width, $height)  = $gdk_window->get_size;
  ### $width
  ### $height

  my $gen = $self->{'gen'};
  my $x_left = $gen->{'x_left'};
  my $y_bottom = $gen->{'y_bottom'};

  # my $gen_width = $gen->{'width'};
  # my $gen_height = $gen->{'height'};
  #
  # my %x11_geometry = $X->GetGeometry($x11_window);
  # my $x11_width = $x11_geometry{'width'};
  # my $x11_width = $x11_geometry{'height'};
  #
  # $x_left -=
  # $y_bottom +=
  # if (! $gen->path_object->class_x_negative) {
  #   $x_left = max($x_left,0);
  # }
  # if (! $gen->path_object->class_y_negative) {
  #   $y_bottom = max($y_bottom,0);
  # }

  $self->{'x11gen'} = App::MathImage::X11::Generator->new
    ((map { ($_ => $gen->{$_}) }
      qw(draw_progressive
         figure
         scale
         foreground
         background
         undrawnground
         path
         path_parameters
         values
         values_parameters
         filter
         widgetcursor
       )),
     x_left => $x_left,
     y_bottom => $y_bottom,
     X => $X,
     window => $x11_window,
     width => $width,
     height => $height);

  return $self;
}

sub _do_read {
  my ($fd, $conditions, $ref_weak_self) = @_;
  ### X11 _do_read()...
  my $self = $$ref_weak_self || return Glib::SOURCE_REMOVE;

  my $X = $self->{'X'} || do {
    ### X gone, stop ...
    return Glib::SOURCE_REMOVE;
  };
  $X->handle_input;

  if (my $x11gen = $self->{'x11gen'}) {
    if (defined $x11gen->{'reply'}) {
      delete $self->{'reply'};

      my $seq = $X->send('QueryPointer', $X->root);
      $X->add_reply($seq, \$self->{'reply'});
      $X->flush;
      ### $seq

      if ($x11gen->draw_steps) {
        ### X11 _do_read() more drawing ...
      } else {
        ### X11 _do_read() drawing finished ...
        delete $self->{'x11gen'};
      }
    }
  } else {
    ### x11gen gone, close X ...
    delete $self->{'X'};
    $X->close;
    return Glib::SOURCE_REMOVE;
  }

  ### SOURCE_CONTINUE ...
  return Glib::SOURCE_CONTINUE;
}

1;
__END__
