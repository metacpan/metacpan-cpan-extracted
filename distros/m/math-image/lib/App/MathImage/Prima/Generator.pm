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


package App::MathImage::Prima::Generator;
use 5.006;
use strict;
use warnings;
use Carp;
use Scalar::Util;

use Image::Base::Prima::Drawable;
use base 'App::MathImage::Generator';

# uncomment this to run the ### lines
#use Smart::Comments '###';

our $VERSION = 110;

use constant 1.02; # for leading underscore
use constant _DEFAULT_IDLE_TIME_SLICE => 0.25;  # seconds
use constant _DEFAULT_IDLE_TIME_FIGURES => 1000;  # drawing requests

sub new {
  my $class = shift;
  ### Prima-Generator new()

  my $self = $class->SUPER::new (step_time    => _DEFAULT_IDLE_TIME_SLICE,
                                 step_figures => _DEFAULT_IDLE_TIME_FIGURES,
                                 use_class_negative => 1,
                                 @_);
  my $widget = $self->{'widget'};
  if ($widget) {
    Scalar::Util::weaken ($self->{'widget'});
  }
  my $drawable = $self->{'drawable'};

  ### width: $drawable->width
  ### height: $drawable->height
  ### draw_progressive: $self->{'draw_progressive'}

  my $bitmap
    =  $self->{'bitmap'}
      = Prima::DeviceBitmap->new (width  => $drawable->width,
                                  height => $drawable->height);
  my $image
    = $self->{'image'}
      = $self->{'bitmap_image'}
        = Image::Base::Prima::Drawable->new (-drawable => $bitmap);

  if ($self->{'draw_progressive'}) {
    my $widget_image
      = Image::Base::Prima::Drawable->new (-drawable => $self->{'drawable'});
    require Image::Base::Multiplex;
    $image
      = $self->{'image'}
        = Image::Base::Multiplex->new (-images => [ $image, $widget_image ]);
  }

  if (! eval { $self->draw_Image_start ($image); 1 }) {
    my $err = $@;
    ### $err;
    # my ($main, $statusbar);
    # if (($main = $self->{'primamain'})
    #     && ($statusbar = $main->get('statusbar'))) {
    #   require Prima::Ex::Statusbar::MessageUntilKey;
    #   $err =~ s/\n+$//;
    #   Prima::Ex::Statusbar::MessageUntilKey->message($statusbar, $err);
    # }
    #
    # undef $self->{'path_object'};
    # App::MathImage::Prima::Drawing::draw_text_centred
    #     ($self->{'widget'}, $self->{'pixmap'}, $err);
    _drawing_finished ($self);
    return $self;
  }

  $self->{'more'} = 1;
  Scalar::Util::weaken (my $weak_self = $self);
  my $id
    = $self->{'id'}
      = $widget->add_notification ('PostMessage',\&on_widget_postmessage);
  $widget->post_message (\$weak_self, $id);

  return $self;
}
sub DESTROY {
  my ($self) = @_;
  if (my $widget = $self->{'widget'}) {
    if (my $id = delete $self->{'id'}) {
      $widget->remove_notification ($id);
    }
  }
}

# Or maybe a private Prima::Object to receive post_message()
sub on_widget_postmessage {
  my ($widget, $ref_weak_self, $id) = @_;
  ### on_widget_postmessage() ...
  my $more;
  if (my $self = $$ref_weak_self) {
    if ($self->{'more'}) {
      $self->{'more'} = 0;

      if ($self->{'draw_progressive'}) {
        # or maybe better a single $widget_image and tell it when a cached
        # $drawable->color() setting must be re-applied
        #    $widget_image->set(-current_colour => '');
        my $widget_image
          = Image::Base::Prima::Drawable->new (-drawable =>
                                               $self->{'drawable'});
        $self->{'image'}->set (-images => [ $self->{'bitmap_image'},
                                            $widget_image ]);
        $self->{'drawable'}->begin_paint
          or die "Oops, cannot begin_paint on drawable: ",$@;
        $more = $self->draw_Image_steps;
        $self->{'drawable'}->end_paint;
      } else {
        $more = $self->draw_Image_steps;
      }

      if ($more) {
        ### keep drawing, further post ...
        $self->{'more'} = 1;
        $widget->post_message ($ref_weak_self, $id);
        return;
      }
      ### drawing done ...
      _drawing_finished ($self);
    }
  }
  $widget->remove_notification($id);
}

sub _drawing_finished {
  my ($self) = @_;
  ### _drawing_finished()

  # ENHANCE-ME: background image ?
  $self->{'drawable'}->repaint;
}

# sub draw {
#   my $class = shift;
#   my $self = $class->new (@_,
#                        draw_progressive => 0);
#   while ($self->draw_steps) {
#     ### Prima-Generator more ...
#   }
#   _drawing_finished ($self);
# }

1;
__END__
