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


package App::MathImage::X11::Generator;
use 5.004;
use strict;
use Carp;
use constant 1.02; # for underscores
use Scalar::Util;
use IO::Select;
use Scope::Guard;
use Time::HiRes;
use X11::Protocol::Other;
use X11::Protocol::XSetRoot; # load always to be sure is available
use Image::Base::X11::Protocol::Window;

use base 'App::MathImage::Generator';
use App::MathImage::X11::Protocol::EventMaskExtra;
use App::MathImage::X11::Protocol::EventHandlerExtra;

# uncomment this to run the ### lines
#use Smart::Comments '###';


use vars '$VERSION';
$VERSION = 110;

use constant _DEFAULT_IDLE_TIME_SLICE => 0.5;  # seconds
use constant _DEFAULT_IDLE_TIME_FIGURES => 1000;  # drawing requests

sub new {
  my $class = shift;
  my $self = $class->SUPER::new (step_time    => _DEFAULT_IDLE_TIME_SLICE,
                                 step_figures => _DEFAULT_IDLE_TIME_FIGURES,
                                 @_);

  my $X = $self->{'X'};
  my $window = $self->{'window'};
  my $colormap = $X->{'default_colormap'};
  my ($width, $height) = X11::Protocol::Other::window_size ($X, $window);

  my $image_window = Image::Base::X11::Protocol::Window->new
    (-X            => $X,
     -window       => $window,
     -colormap     => $colormap);

  require Image::Base::X11::Protocol::Pixmap;
  my $image_pixmap = $self->{'image_pixmap'}
    = Image::Base::X11::Protocol::Pixmap->new
      (-X            => $X,
       -width        => $width,
       -height       => $height,
       -colormap     => $colormap,
       -for_drawable => $window);
  $self->{'pixmap'} = $image_pixmap->get('-pixmap');
  ### pixmap: $self->{'pixmap'}

  require Image::Base::Multiplex;
  my $image = Image::Base::Multiplex->new
    (-images => [ $image_pixmap, $image_window ]);

  $self->draw_Image_start ($image);

  # blank old background while drawing
  $X->ChangeWindowAttributes ($window, background_pixmap => $self->{'pixmap'});

  my $seq = $X->send('QueryPointer', $X->root);
  $X->add_reply($seq, \$self->{'reply'});
  $X->flush;

  return $self;
}

# free the pixmap if draw_Image_steps() stopped before completion
sub DESTROY {
  my ($self) = @_;
  if ((my $X = $self->{'X'})
      && (my $pixmap = $self->{'pixmap'})) {
    # ignore errors if closed, maybe
    eval { $X->FreePixmap ($pixmap) };
  }
}

sub draw {
  my ($self) = @_;
  ### X11-Generator draw()

  my $X = $self->{'X'};
  my $window = $self->{'window'};
  my $pixmap = $self->{'pixmap'};

  my $fh = $X->{'connection'}->fh;
  my $sel = $fh && IO::Select->new($fh);

  my $extra_events = App::MathImage::X11::Protocol::EventMaskExtra->new
    ($X, $window, $X->pack_event_mask('Exposure'));

  my $extra_handler = App::MathImage::X11::Protocol::EventHandlerExtra->new
    ($X, sub {
       my %h = @_;
       ### X11-Generator event_handler: \%h
       if ($h{'name'} eq 'Expose' && $h{'window'} == $window) {
         $X->ChangeWindowAttributes ($window, background_pixmap => $pixmap);
         $X->ClearArea ($window, @h{'x','y','width','height'});
       }
     });

  ### step_figures: $self->{'step_figures'}
  ### step_time: $self->{'step_time'}

  for (;;) {
    while ($sel && $sel->can_read(0)) {
      ### handle_input
      $X->handle_input;
    }
    if (! $self->draw_steps) {
      last;
    }
    $X->flush;
    ### X11-Generator draw() more
  }
}

sub draw_steps {
  my ($self) = @_;
  ### X11-Generator draw_steps() ...

  my $more = $self->draw_Image_steps;
  if (! $more) {
    ### Generator-X11 finished
    my $window = $self->{'window'};

    my $image_pixmap = delete $self->{'image_pixmap'};
    my $allocated = _image_pixmap_any_allocated_colours($image_pixmap);
    ### $allocated

    # destroy images to free GCs
    delete $self->{'image'};
    delete $self->{'values_seq'};
    undef $image_pixmap;

    if ($self->{'flash'}) {
      require App::MathImage::X11::Protocol::Splash;
      my $splash = App::MathImage::X11::Protocol::Splash->new
        (X      => $self->{'X'},
         pixmap => $self->{'pixmap'},
         width  => $self->{'width'},
         height => $self->{'height'});
      $splash->popup;
      $self->{'X'}->QueryPointer($window);  # sync

      Time::HiRes::sleep (0.75);
    }

    # $self->{'X'}->QueryPointer($window);  # sync
    X11::Protocol::XSetRoot->set_background
        (X      => $self->{'X'},
         root   => $window,
         pixmap => delete $self->{'pixmap'},
         pixmap_allocated_colors => $allocated,
         use_esetroot => 1);
  }

  return $more;
}

# x_resource_dump($self->{'X'});
# # my $image_win = $self->{'image'}->get('-images')->[1];
# # Scalar::Util::weaken($image_win);
# # Scalar::Util::weaken($image_pixmap);
# x_resource_dump($self->{'X'});
# # ### $self
# use Devel::FindRef;
# # if ($image_win) {
# #   print Devel::FindRef::track($image_win);
# # }
# if ($image_pixmap) {
#   print Devel::FindRef::track($image_pixmap);
# }
#
# x_resource_dump($self->{'X'});

sub _image_pixmap_any_allocated_colours {
  my ($image) = @_;
  my $colour_to_pixel = $image->get('-colour_to_pixel')
    || return 1;  # umm, dunno
  %$colour_to_pixel or return 0;  # no colours at all

  my $X        = $image->get('-X');
  my $screen   = $image->get('-screen');
  my $colormap = $image->get('-colormap') || return 0;  # no colormap

  my $screen_info = $X->{'screens'}->[$screen];
  if ($colormap != $screen_info->{'default_colormap'}) {
    return 1;  # private colormap
  }

  foreach my $pixel (values %$colour_to_pixel) {
    unless ($pixel == $screen_info->{'black_pixel'}
            || $pixel == $screen_info->{'white_pixel'}) {
      return 1;
    }
  }
  return 0; # only black and white and in the default colormap
}

1;
__END__
