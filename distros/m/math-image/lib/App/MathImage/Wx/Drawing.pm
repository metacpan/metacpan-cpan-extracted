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



# wxMouseEvent move offset




package App::MathImage::Wx::Drawing;
use strict;
use Wx;
use Module::Load;

use base 'Wx::Window';
our $VERSION = 110;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant _IDLE_TIME_SLICE => 0.25;  # seconds
use constant _IDLE_TIME_FIGURES => 1000;  # drawing requests

sub new {
  my ($class, $parent) = @_;
  ### Drawing new(): $parent

  my $self = $class->SUPER::new ($parent);
  $self->SetWindowStyle (Wx::wxFULL_REPAINT_ON_RESIZE());

  $self->{'x_offset'} = 0;
  $self->{'y_offset'} = 0;
  my $options = App::MathImage::Generator->default_options;
  %$self = (%$self,
            %$options);
  $self->{'scale'} = 3;

  Wx::Event::EVT_PAINT ($self, 'OnPaint');
  Wx::Event::EVT_SIZE ($self, '_OnSize');
  Wx::Event::EVT_IDLE ($self, '_OnIdle');
  Wx::Event::EVT_MOUSEWHEEL ($self, 'OnMouseWheel');
  Wx::Event::EVT_LEFT_DOWN ($self, 'OnLeftDown');
  Wx::Event::EVT_MOTION ($self, 'OnMotion');
  Wx::Event::EVT_ENTER_WINDOW ($self, 'OnMotion');
  Wx::Event::EVT_LEAVE_WINDOW ($self, 'OnLeaveWindow');
  return $self;
}

sub redraw {
  my ($self) = @_;
  delete $self->{'bitmap'};
  delete $self->{'gen_object'};
  $self->Refresh;
}

sub _OnSize {
  my ($self, $event) = @_;
  $self->Refresh;

  # my $old_width = $self->allocation->width;
  # my $old_height = $self->allocation->height;
  # ### _do_size_allocate(): $alloc->width."x".$alloc->height
  # ### $old_width
  # ### $old_height
  # 
  # shift->signal_chain_from_overridden(@_);
  # 
  # _update_adjustment_extents($self);
  # my $scale = $self->get('scale');
  # _update_adjustment_values ($self,
  #                            $old_width / $scale,
  #                            $old_height / $scale,
  #                            $self->allocation->width / $scale,
  #                            $self->allocation->height / $scale);
}

sub OnPaint {
  my ($self, $event) = @_;
  ### Drawing OnPaint(): $event
  ### foreground: $self->GetForegroundColour->GetAsString(4)
  ### background: $self->GetBackgroundColour->GetAsString(4)

  my $dc = Wx::PaintDC->new ($self);
  my $brush = $dc->GetBrush;
  my $c = $self->GetBackgroundColour;
  ### colour: $c->GetAsString(4)
  $brush->SetColour ($c);
  # $dc->SetBrush ($brush);
  $dc->Clear;

  # $dc->DrawRectangle (0,0,200,200);
  # 
  # $dc->SetFont($self->GetFont);
  # $dc->DrawText('Hello', 10, 10);

  # require Image::Base::Wx::DC;
  # my $image = Image::Base::Wx::DC->new (-dc => $dc);

  # $image->rectangle (5,30,15,40, 'blue', 1);
  # $image->rectangle (25,30,35,40, 'green', 0);
  # 
  # $image->ellipse (5,50,35,70, 'black', 1);
  # $image->ellipse (45,50,75,70, 'magenta', 0);
  # 
  # $image->rectangle (5,80,15,100, 'orange', 1);
  # $image->rectangle (25,80,35,100, 'pink', 0);
  # 
  # $image->diamond (5,110,35,130, 'black', 1);
  # $image->diamond (45,110,75,130, 'magenta', 0);
  # 
  # $image->xy (2,3, 'orange');


  ### _bitmap_is_good says: _bitmap_is_good($self)
  if (my $bitmap = $self->bitmap) {
    $dc->DrawBitmap ($bitmap, 0, 0, 0);
  }

  # if (my $bitmap = $self->{'gen_object'}->{'bitmap'}) {
  #   $win->draw_drawable ($self->style->black_gc, $bitmap,
  #                        $event->area->x,
  #                        $event->area->y,
  #                        $event->area->values);
  # }
}

sub bitmap {
  my ($self) = @_;
  ### bitmap()...
  if (! _bitmap_is_good($self)) {
    ### new bitmap...
    $self->start_drawing_window ($self);
  }
  return $self->{'bitmap'};
}
sub _bitmap_is_good {
  my ($self) = @_;
  ### _bitmap_is_good() ...
  ### bitmap: $self->{'bitmap'}
  my $bitmap = $self->{'bitmap'} || return 0;
  my ($window_width, $window_height) = $self->GetClientSizeWH;
  ### sizes: $window_width, $bitmap->GetWidth, $window_height, $bitmap->GetHeight
  return ($window_width == $bitmap->GetWidth
          && $window_height == $bitmap->GetHeight);
}

sub start_drawing_window {
  my ($self, $target) = @_;
  ### Wx-Drawing start_drawing_window() ...

  $self->SetExtraStyle($self->GetExtraStyle
                       | Wx::wxWS_EX_PROCESS_IDLE());

  # {
  #   my $style = $self->style;
  #   my $background_colorobj = $style->bg($self->state);
  #   $window->set_background ($background_colorobj);
  # }

  delete $self->{'gen_object'};
  my $gen = $self->gen_object
    (generator_class => 'App::MathImage::Wx::Generator',
     busycursor      => Wx::BusyCursor->new);
  # ### $gen

  # if drawing to self, not if drawing to root window
  if ($target == $self) {
    $self->{'bitmap'} = $gen->{'bitmap'};
  }
}

sub gen_object_maybe {
  my ($self, %gen_parameters) = @_;
  return eval { $self->gen_object };
}
sub gen_object {
  my ($self, %gen_parameters) = @_;
  return ($self->{'gen_object'} ||= do {
    ### Wx-Drawing gen_object() create ...
    ### %gen_parameters

    my $size = $self->GetClientSize;
    my $width = $size->GetWidth;
    my $height = $size->GetHeight;
    ### $size
    ### $width
    ### $height
    ### path_parameters: $self->{'path_parameters'}

    my $background_colorobj = $self->GetBackgroundColour;
    my $foreground_colorobj = $self->GetForegroundColour;

    my $generator_class = delete $gen_parameters{'generator_class'}
      || 'App::MathImage::Generator';
    ### $generator_class
    ### scale: $self->{'scale'}

    Module::Load::load ($generator_class);
    $generator_class->new
      (widget  => $self,
       window  => $self,
       wxframe => $self->GetParent,

       foreground       => $foreground_colorobj->GetAsString(Wx::wxC2S_HTML_SYNTAX()),
       background       => $background_colorobj->GetAsString(Wx::wxC2S_HTML_SYNTAX()),
       draw_progressive => 1, # $self->get('draw-progressive'),

       width           => $width,
       height          => $height,
       step_time       => _IDLE_TIME_SLICE,
       step_figures    => _IDLE_TIME_FIGURES,

       values          => $self->{'values'},
       values_parameters => $self->{'values_parameters'},

       path            => $self->{'path'},
       path_parameters => $self->{'path_parameters'},

       scale           => $self->{'scale'},
       figure          => $self->{'figure'},

       filter          => $self->{'filter'},
       x_offset        => $self->{'x_offset'},
       y_offset        => $self->{'y_offset'},

       %gen_parameters)
    });
}
sub x_negative {
  my ($self) = @_;
  return $self->gen_object->x_negative;
}
sub y_negative {
  my ($self) = @_;
  return $self->gen_object->y_negative;
}

sub _OnIdle {
  my ($self, $event) = @_;
  # ### Wx-Drawing OnIdle() ...
  if (my $gen = $self->{'gen_object'}) {
    $gen->OnIdle ($event);
  }
}

#------------------------------------------------------------------------------
# mouse wheel scroll

sub OnMouseWheel {
  my ($self, $event) = @_;
  ### OnMouseWheel() ..

  # "Control" by page, otherwise by step
  my $frac = ($event->ControlDown ? 0.9 : 0.1)
    * $event->GetWheelRotation / $event->GetWheelDelta;

  # "Shift" horizontally, otherwise vertically
  my $size = $self->GetClientSize;
  if ($event->ShiftDown) {
    $self->{'x_offset'} += int($size->GetWidth * $frac);
  } else {
    $self->{'y_offset'} -= int($size->GetHeight * $frac);
  }
  $self->redraw;
}


#------------------------------------------------------------------------------
# mouse drag

# $event is a wxMouseEvent
sub OnLeftDown {
  my ($self, $event) = @_;
  ### Draw OnLeftDown() ...
  $self->{'drag_x'} = $event->GetX;
  $self->{'drag_y'} = $event->GetY;
  $event->Skip(1); # propagate to other processing
}
sub OnMotion {
  my ($self, $event) = @_;
  ### Draw OnMotion() ...

  if ($event->Dragging) {
    if (defined $self->{'drag_x'}) {
      ### drag ...
      my $x = $event->GetX;
      my $y = $event->GetY;
      $self->{'x_offset'} += $x - $self->{'drag_x'};
      $self->{'y_offset'} -= $y - $self->{'drag_y'};
      $self->{'drag_x'} = $x;
      $self->{'drag_y'} = $y;
      $self->redraw;
    }
  } else {
    ### mouse motion ...
    if (my $main = $self->GetParent) {
      $main->mouse_motion ($event);
    }
  }
}
sub OnLeaveWindow {
  my ($self, $event) = @_;
  if (my $main = $self->GetParent) {
    $main->mouse_motion (undef);
  }
}

# sub pointer_xy_to_image_xyn {
#   my ($self, $x, $y) = @_;
#   ### pointer_xy_to_image_xyn(): "$x,$y"
#   my $affine_object = $self->{'affine_object'} || return;
#   my ($px,$py) = $affine_object->clone->invert->transform($x,$y);
#   ### $px
#   ### $py
#   my $path_object =  $self->{'path_object'}
#     || return ($px, $py);
#   if ($path_object->figure eq 'square') {
#     $px = POSIX::floor ($px + 0.5);
#     $py = POSIX::floor ($py + 0.5);
#   }
#   return ($px, $py, $path_object->xy_to_n($px,$py));
# }

1;
__END__

