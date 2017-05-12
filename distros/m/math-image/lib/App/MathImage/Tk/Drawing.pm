# Copyright 2011, 2012, 2013 Kevin Ryde

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

package App::MathImage::Tk::Drawing;
use 5.008;
use strict;
use warnings;
use Tk;
use Image::Base::Tk::Photo;
use App::MathImage::Tk::Perl::WeakAfter;

use base 'Tk::Derived', 'Tk::Label';
Tk::Widget->Construct('AppMathImageTkDrawing');

our $VERSION = 110;

sub ClassInit {
  my ($class, $mw) = @_;
  ### ClassInit(): $class
  $class->SUPER::ClassInit($mw);
  # event handlers for all instances
  $mw->bind($class,'<Expose>',\&_do_expose);
  $mw->bind($class,'<Configure>',\&queue_reimage);
  $mw->bind($class,'<Button-1>', ['DragStart', Ev('x'), Ev('y')]);
  $mw->bind($class,'<B1-Motion>', ['DragMotion', Ev('x'), Ev('y')]);
  $mw->bind($class,'<MouseWheel>', ['MouseWheel', Ev('delta'), Ev('s')]);
  $mw->bind($class,'<Button-4>', ['MouseWheel', 120, Ev('s')]);
  $mw->bind($class,'<Button-5>', ['MouseWheel', -120, Ev('s')]);
}

sub Populate {
  my ($self, $args) = @_;
  ### Drawing Populate(): $args

  my %args = (-background         => 'black',
              -foreground         => 'white',
              -activebackground   => 'black',
              -activeforeground   => 'white',
              -disabledforeground => 'white',
              -borderwidth        => 0, # default

              # must initial -image so that Tk::Label -width and -height are
              # interpreted as pixels, not lines/columns
              -image  => $self->Photo (-width => 1, -height => 1),
              -width  => 1, # desired size any size, not from -image
              -height => 1,

              %$args,
             );
  $self->SUPER::Populate(\%args);

  ### background: $self->cget('-background')
  ### borderwidth: $self->cget('-borderwidth')
  $self->{'dirty'} = 1;
  $self->{'aft'} = App::MathImage::Tk::Perl::WeakAfter->new;
}

sub destroy {
  my ($self) = @_;
  ### Drawing destroy() ...
  if (my $image = $self->cget('-image')) {
    $self->configure('-image',undef);
    $image->delete;
  }
  shift->SUPER::destroy(@_);
}
# sub DESTROY {
#   my ($self) = @_;
#   ### Drawing DESTROY() ...
#   shift->SUPER::DESTROY(@_);
# }

sub queue_reimage {
  my ($self) = @_;
  ### queue_reimage() ...
  ### background: $self->cget('-background')
  $self->{'dirty'} = 1;
  delete $self->{'gen_object'};
  $self->{'aft'}->idle($self, \&_do_expose);
}
sub _do_expose {
  my ($self) = @_;
  ### Drawing Expose() ...
  if (! $self->{'dirty'}) {
    return;
  }
  $self->{'dirty'} = 0;
  if (my $id = delete $self->{'draw_id'}) { $id->cancel; }

  my $gen = $self->gen_object;

  my $borderwidth = $self->cget('-borderwidth');
  my $width = $self->width - 2*$borderwidth;
  my $height = $self->height - 2*$borderwidth;

  my $photo = $self->cget('-image');
  if ($photo) {
    $photo->configure(-width => $width,
                      -height => $height);
  } else {
    $photo = $self->Photo (-width => $width, -height => $height);
    $self->configure (-image => $photo);
  }
  my $image = Image::Base::Tk::Photo->new (-tkphoto => $photo);
  $gen->draw_Image_start ($image);

  # FIXME: want some sort of low-priority after()
  #
  $self->{'aft'}->after($self, 20, \&_update_draw_steps);
  $self->configure(-cursor => 'watch');
}
sub _update_draw_steps {
  my ($self) = @_;
  ### _update_draw_steps() some ...
  my $gen = $self->gen_object;
  if ($gen->draw_Image_steps) {
    ### _update_draw_steps() more ...
    $self->{'aft'}->after($self, 20, \&_update_draw_steps);
  } else {
    ### _update_draw_steps() finished
    $self->configure (-cursor => undef);
  }
}

sub gen_object {
  my ($self) = @_;
  return ($self->{'gen_object'} ||= do {
    my $gen_options = $self->{'gen_options'} || {};
    ### $gen_options

    my $background = $self->cget('-background');
    my $foreground = $self->cget('-foreground');
    my $borderwidth = $self->cget('-borderwidth');
    my $width = $self->width - 2*$borderwidth;
    my $height = $self->height - 2*$borderwidth;
    ### $width
    ### $height
    ### $background
    ### $foreground
    ### state: $self->cget('-state')

    App::MathImage::Generator->new
        (step_time       => 0.5,
         step_figures    => 1000,
         %$gen_options,
         width => $width,
         height => $height,
         # background => $background,
         # foreground => $foreground,
        )
      });
}

sub centre {
  my ($self) = @_;
  my $gen_options = $self->{'gen_options'};
  if ($gen_options->{'x_offset'} || $gen_options->{'y_offset'}) {
    $gen_options->{'x_offset'} = 0;
    $gen_options->{'y_offset'} = 0;
    $self->queue_reimage;
  }
}

#------------------------------------------------------------------------------
# mouse wheel

sub MouseWheel {
  my ($self, $delta, $state) = @_;
  ### MouseWheel() ...
  ### $delta
  ### $state

  # "Control" by page, otherwise by step
  my $frac = ($state =~ /control/i ? 0.9 : 0.1) * $delta/120;

  # "Shift" horizontally, otherwise vertically
  if ($state =~ /shift/i) {
    $self->{'gen_options'}->{'x_offset'} += int($self->width * $frac);
  } else {
    $self->{'gen_options'}->{'y_offset'} -= int($self->height * $frac);
  }
  $self->queue_reimage;
}

#------------------------------------------------------------------------------
# mouse drag

# $event is a wxMouseEvent
sub DragStart {
  my ($self, $x, $y) = @_;
  ### Drawing DragStart() ...
  $self->{'drag_x'} = $x;
  $self->{'drag_y'} = $y;
}
sub DragMotion {
  my ($self, $x, $y) = @_;
  ### Drawing DragMotion() ...

  if (defined $self->{'drag_x'}) {
    ### drag ...
    $self->{'gen_options'}->{'x_offset'} += $x - $self->{'drag_x'};
    $self->{'gen_options'}->{'y_offset'} -= $y - $self->{'drag_y'};
    $self->{'drag_x'} = $x;
    $self->{'drag_y'} = $y;
    $self->queue_reimage;
  }
}

1;
__END__
