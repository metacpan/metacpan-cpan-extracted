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


package App::MathImage::Gtk1::Generator;
use 5.004;
use strict;
use Carp;
use Scalar::Util;
use Image::Base::Gtk::Gdk::Pixmap;
use Image::Base::Gtk::Gdk::Window;

use vars '$VERSION','@ISA';
$VERSION = 110;

use App::MathImage::Generator;
@ISA = ('App::MathImage::Generator');

# uncomment this to run the ### lines
#use Devel::Comments '###';


use constant _DEFAULT_IDLE_TIME_SLICE => 0.25;  # seconds
use constant _DEFAULT_IDLE_TIME_FIGURES => 1000;  # drawing requests
use constant _PRIORITY => 300;  # below redraw

### *DESTROY = sub { print "Gtk1-Generator DESTROY\n" }

sub new {
  my $class = shift;
  ### Gtk1-Generator new()...

  my $self = $class->SUPER::new (step_time    => _DEFAULT_IDLE_TIME_SLICE,
                                 step_figures => _DEFAULT_IDLE_TIME_FIGURES,
                                 # idle_ids     => App::MathImage::Gtk::Ex::IdleIds->new,
                                 use_class_negative => 1,
                                 @_);
  if ($self->{'gtkmain'}) { Scalar::Util::weaken ($self->{'gtkmain'}); }
  if ($self->{'widget'})  { Scalar::Util::weaken ($self->{'widget'}); }

  # either Drawing widget window or rootwin
  ### window: "$self->{'window'}"
  my $window = $self->{'window'}
    || croak 'Gtk1-Generator no window specified';
  my ($width, $height) = $window->get_size;

  my $image = Image::Base::Gtk::Gdk::Pixmap->new
    (-for_drawable => $window,
     -colormap     => Gtk::Gdk::Colormap->get_system,
     -depth        => 24,
     -width        => $width,
     -height       => $height);
  $self->{'pixmap'} = $image->get('-pixmap');

  if ($self->{'draw_progressive'}) {
    require Image::Base::Gtk::Gdk::Window;
    my $image_window = Image::Base::Gtk::Gdk::Window->new
      (-drawable => $window,
       -colormap => Gtk::Gdk::Colormap->get_system);
    $window->clear;

    require Image::Base::Multiplex;
    $image = Image::Base::Multiplex->new
      (-images => [ $image, $image_window ]);
  }
  $self->{'image'} = $image;

  if (! eval { $self->draw_Image_start ($image); 1 }) {
    my $err = $@;
    ### $err
    my ($main, $statusbar);
    if (($main = $self->{'gtkmain'})
        && ($statusbar = $main->get('statusbar'))) {
      ### $statusbar
      require Gtk::Ex::Statusbar::MessageUntilKey;
      $err =~ s/\n+$//;  # no trailing newlines
      Gtk::Ex::Statusbar::MessageUntilKey->message($statusbar, $err);
    }

    undef $self->{'path_object'};
    undef $self->{'affine_object'};
    App::MathImage::Gtk1::Drawing::draw_text_centred
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
  ### Gtk1-Generator _sync_handler()...
  my $self = $$ref_weak_self || return;

  $self->{'sync_pending'} = 0;
  if (my $id = delete $self->{'idle_id'}) {
    Gtk->idle_remove ($id);
  }
  $self->{'idle_id'} ||= Gtk->idle_add_priority (_PRIORITY(),
                                                 \&_idle_handler_draw,
                                                 $ref_weak_self);
}

sub _idle_handler_draw {
  my ($ref_weak_self) = @_;
  ### Gtk1-Generator _idle_handler_draw()...

  if (my $self = $$ref_weak_self) {
    Gtk->idle_remove (delete $self->{'idle_id'});
    if ($self->draw_Image_steps ()) {
      ### keep drawing...
      # Gtk::Gdk->flush;
      # _sync_handler($ref_weak_self);

      unless ($self->{'sync_pending'}) {
        ### start sync...
        require App::MathImage::Gtk1::Ex::SyncCall;
        App::MathImage::Gtk1::Ex::SyncCall->sync ($self->{'widget'},
                                                  \&_sync_handler,
                                                  $ref_weak_self);
        $self->{'sync_pending'} = 1;
      }

    } else {
      ### done, install pixmap...
      _drawing_finished ($self);
    }
  }
  ### _idle_handler_draw() end...
  return 0;  # remove
}

sub _drawing_finished {
  my ($self) = @_;
  ### Gtk1-Generator _drawing_finished()...

  my $pixmap = $self->{'pixmap'};
  my $window = $self->{'window'};
  ### set_back_pixmap: "$pixmap"
  $window->set_back_pixmap ($pixmap,
                            0); # self relative, not parent
  # FIXME: whole window pending 1.240 for undef rectangle for all
  $window->clear;
# invalidate_rect (Gtk1::Gdk::Rectangle->new (0,0, $window->get_size),
#                             0);
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
