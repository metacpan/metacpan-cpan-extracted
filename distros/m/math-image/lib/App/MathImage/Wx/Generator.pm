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


package App::MathImage::Wx::Generator;
use 5.004;
use strict;
use Carp;
use Scalar::Util;

use base 'App::MathImage::Generator';

# uncomment this to run the ### lines
# use Smart::Comments '###';

our $VERSION = 110;

use constant _DEFAULT_IDLE_TIME_SLICE => 0.25;  # seconds
use constant _DEFAULT_IDLE_TIME_FIGURES => 1000;  # drawing requests
use constant _PRIORITY => 0;  # below redraw

sub new {
  my $class = shift;
  ### Wx-Generator new(): @_

  my $self = $class->SUPER::new (step_time    => _DEFAULT_IDLE_TIME_SLICE,
                                 step_figures => _DEFAULT_IDLE_TIME_FIGURES,
                                 use_class_negative => 1,
                                 @_);
  if ($self->{'wxframe'}) { Scalar::Util::weaken ($self->{'wxframe'}); }
  if ($self->{'widget'})  { Scalar::Util::weaken ($self->{'widget'}); }

  {
    my $values_class = $self->values_class($self->{'values'});
    if (exists $values_class->parameter_info_hash->{'planepath'}) {
      $self->{'values_parameters'}->{'planepath'} ||= 'ThisPath';
    }
  }

  # either Drawing widget window or rootwin
  ### window: "$self->{'window'}"
  my $window = $self->{'window'}
    || croak 'Wx-Generator no window specified';
  my $size = $window->GetClientSize;
  my $width = $size->GetWidth;
  my $height = $size->GetHeight;
  ### $size
  ### $width
  ### $height

  ### bitmap: "$width, $height"
  my $bitmap = Wx::Bitmap->new ($width, $height);
  $self->{'bitmap'} = $bitmap;
  my $dc = Wx::MemoryDC->new;
  $dc->SelectObject($bitmap);

  require Image::Base::Wx::DC;
  my $image = Image::Base::Wx::DC->new
    (-dc => $dc);

  if ($self->{'draw_progressive'}) {
    my $windc = Wx::ClientDC->new ($self->{'widget'});
    my $image_window = Image::Base::Wx::DC->new
      (-dc => $windc);

    require Image::Base::Multiplex;
    $image = Image::Base::Multiplex->new
      (-images => [ $image, $image_window ]);
  }
  $self->{'image'} = $image;

  if (! eval { $self->draw_Image_start ($image); 1 }) {
    my $err = $@;
    ### $err;
    my ($frame, $statusbar);
    if (($frame = $self->{'wxframe'})
        && ($statusbar = $frame->GetStatusBar)) {
      $err =~ s/\n+$//;
      $statusbar->SetStatusText ($err, 0);

      # require Wx::Ex::Statusbar::MessageUntilKey;
      # Wx::Ex::Statusbar::MessageUntilKey->message($statusbar, $err);
    }

    undef $self->{'path_object'};
    undef $self->{'affine_object'};
    warn $err;
    # App::MathImage::Wx::Drawing::draw_text_centred
    #     ($self->{'widget'}, $self->{'bitmap'}, $err);
    _drawing_finished ($self);
    return $self;
  }

  $self->{'more'} = 1;
  $self->OnIdle;
  return $self;

  # Scalar::Util::weaken (my $weak_self = $self);
  # _sync_handler (\$weak_self);
}

# sub _sync_handler {
#   my ($ref_weak_self) = @_;
#   ### Wx-Generator _sync_handler()...
#   my $self = $$ref_weak_self || return;
# 
#   # $self->{'sync_pending'} = 0;
#   # ### add idle: $self->{'idle_ids'}
#   # $self->{'idle_ids'}->remove;
# 
#   # $self->{'idle_ids'}->add (Glib::Idle->add (\&_idle_handler_draw,
#   #                                            $ref_weak_self,
#   #                                            _PRIORITY));
# 
#   my $window = $self->{'window'};
#   # $window->Connect (99, 100, Wx::wxEVT_IDLE(), \&_idle_handler_draw, $ref_weak_self);
#   # , wxObject*
#   # userData = NULL, wxEvtHandler* eventSink = NULL)
# 
#   #   my $evt = $self->{'evt_handler'} = Wx::EvtHandler->new;
#   # EVT_IDLE($evt,'
# 
#   $self->{'more'} = 1;
#   $self->OnIdle;
# }

sub OnIdle {
  my ($self, $event) = @_;
  ### Wx-Generator OnIdle() ...

  if ($self->{'more'}) {
    if ($self->draw_Image_steps ()) {
      ### keep drawing...
      if ($event) {
        ### RequestMore ...
        $event->RequestMore(1);
      }

      # unless ($self->{'sync_pending'}) {
      #   ### start sync...
      #   Wx::Ex::SyncCall->sync ($self->{'widget'},
      #                             \&_sync_handler, $ref_weak_self);
      #   $self->{'sync_pending'} = 1;
      # }
      # _sync_handler ($ref_weak_self);

    } else {
      ### Wx-Generator OnIdle() draw_Image_steps says done, install bitmap...
      $self->{'more'} = 0;
      _drawing_finished ($self);
    }
  }
}

sub _drawing_finished {
  my ($self) = @_;
  ### Wx-Generator _drawing_finished()...

  # my $bitmap = $self->{'bitmap'};
  # my $window = $self->{'window'};
  # ### set_back_bitmap: "$bitmap"
  # $window->set_back_bitmap ($bitmap);
#   $window->clear;

  Scalar::Util::weaken ($self->{'busycursor'});
  if (my $wc = $self->{'widgetcursor'}) {
    $wc->active(0);
  }

  # if ($drawing->{'window'} == $self->window) {
  #   $self->queue_draw;
  # } else {
  #   $window->clear;  # for root window
  # }
}

sub draw {
  my $class = shift;
  my $self = $class->new (@_,
                          draw_progressive => 0);
  while ($self->draw_steps) {
    ### Generator-X11 more...
  }
  _drawing_finished ($self);
}

1;
__END__
