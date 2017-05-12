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


package App::MathImage::Gtk2::Generator;
use 5.008;
use strict;
use warnings;
use Carp;
use Scalar::Util;
use Glib 1.220; # for SOURCE_REMOVE
use Glib::Ex::SourceIds;

use Image::Base::Gtk2::Gdk::Pixmap;
use base 'App::MathImage::Generator';

# uncomment this to run the ### lines
#use Devel::Comments '###';


our $VERSION = 110;

use constant _DEFAULT_IDLE_TIME_SLICE => 0.25;  # seconds
use constant _DEFAULT_IDLE_TIME_FIGURES => 1000;  # drawing requests
use constant _PRIORITY => Glib::G_PRIORITY_LOW();  # below redraw

### *DESTROY = sub { print "Gtk2-Generator DESTROY\n" }

sub new {
  my $class = shift;
  ### Gtk2-Generator new()...

  my $self = $class->SUPER::new (step_time    => _DEFAULT_IDLE_TIME_SLICE,
                                 step_figures => _DEFAULT_IDLE_TIME_FIGURES,
                                 idle_ids     => Glib::Ex::SourceIds->new,
                                 use_class_negative => 1,
                                 @_);
  if ($self->{'gtkmain'}) { Scalar::Util::weaken ($self->{'gtkmain'}); }
  if ($self->{'widget'})  { Scalar::Util::weaken ($self->{'widget'}); }
  # if ($self->{'window'})  { Scalar::Util::weaken ($self->{'window'}); }

  # print "new \"widget\" $self->{'widget'} isweak ",
  #   Scalar::Util::isweak($self->{'widget'}),"\n";

  ### widget: "$self->{'widget'}"
  # either Drawing widget window or rootwin
  my $window = $self->{'window'}
    || $self->{'widget'}->window
      || do {
        ### no window ...
        return $self; # croak 'Gtk2-Generator no window specified';
      };
  ### window: "$window"
  my ($width, $height) = $window->get_size;

  my $image = Image::Base::Gtk2::Gdk::Pixmap->new
    (-for_drawable => $window,
     -width        => $width,
     -height       => $height);
  $self->{'pixmap'} = $image->get('-pixmap');

  if ($self->{'draw_progressive'}) {
    require Image::Base::Gtk2::Gdk::Window;
    my $image_window = Image::Base::Gtk2::Gdk::Window->new
      (-window => $window);

    require Image::Base::Multiplex;
    $image = Image::Base::Multiplex->new
      (-images => [ $image, $image_window ]);
  }
  $self->{'image'} = $image;

  if (! eval { $self->draw_Image_start ($image); 1 }) {
    my $err = $@;
    ### $err;
    my ($main, $statusbar);
    if (($main = $self->{'gtkmain'})
        && ($statusbar = $main->get('statusbar'))) {
      require Gtk2::Ex::Statusbar::MessageUntilKey;
      $err =~ s/\n+$//;
      Gtk2::Ex::Statusbar::MessageUntilKey->message($statusbar, $err);
    }

    undef $self->{'path_object'};
    undef $self->{'affine_object'};
    App::MathImage::Gtk2::Drawing::draw_text_centred
        ($self->{'widget'}, $self->{'pixmap'}, $err);
    _drawing_finished ($self);
    return $self;
  }

  Scalar::Util::weaken (my $weak_self = $self);
  _sync_handler (\$weak_self);
  return $self;
}

sub _sync_handler {
  my ($ref_weak_self) = @_;
  ### Gtk2-Generator _sync_handler()...
  my $self = $$ref_weak_self || return;

  $self->{'sync_pending'} = 0;
  ### add idle: $self->{'idle_ids'}
  $self->{'idle_ids'}->remove;
  $self->{'idle_ids'}->add (Glib::Idle->add (\&_idle_handler_draw,
                                             $ref_weak_self,
                                             _PRIORITY));
}

sub _idle_handler_draw {
  my ($ref_weak_self) = @_;
  ### Gtk2-Generator _idle_handler_draw()...

  if (my $self = $$ref_weak_self) {
    $self->{'idle_ids'}->remove;
    if ($self->draw_Image_steps ()) {
      ### keep drawing...
      unless ($self->{'sync_pending'}) {
        ### start sync...
        Gtk2::Ex::SyncCall->sync ($self->{'widget'},
                                  \&_sync_handler, $ref_weak_self);
        $self->{'sync_pending'} = 1;
      }
    } else {
      ### done, install pixmap...
      _drawing_finished ($self);
    }
  }
  ### _idle_handler_draw() end...
  return Glib::SOURCE_REMOVE;
}

sub _drawing_finished {
  my ($self) = @_;
  ### Gtk2-Generator _drawing_finished()...

  my $pixmap = $self->{'pixmap'};
  my $window = $self->{'window'};
  ### set_back_pixmap: "$pixmap"
  $window->set_back_pixmap ($pixmap);
  $window->clear;

  if (my $wc = $self->{'widgetcursor'}) {
    $wc->active(0);
    # Scalar::Util::weaken($wc);
    # ### $wc
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
