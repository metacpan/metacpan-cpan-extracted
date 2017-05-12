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


package App::MathImage::Gtk2::Drawing;
use 5.008;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use POSIX ();
use Scalar::Util;
use Module::Load;
use App::MathImage::Generator;
use Glib 1.220; # for Glib::SOURCE_REMOVE and probably more
use Gtk2 1.220; # for Gtk2::EVENT_PROPAGATE and probably more
use Gtk2::Pango;
use Locale::TextDomain ('App-MathImage');

use Glib::Ex::SourceIds;
use Glib::Ex::SignalIds;
use Gtk2::Ex::SyncCall 12; # v.12 workaround gtk 2.12 bug
use Gtk2::Ex::GdkBits 23; # v.23 for window_clear_region()

use App::MathImage::Gtk2::Drawing::Values;
use App::MathImage::Gtk2::Ex::AdjustmentBits;



our $VERSION = 110;

use constant _IDLE_TIME_SLICE => 0.25;  # seconds
use constant _IDLE_TIME_FIGURES => 1000;  # drawing requests

BEGIN {
  Glib::Type->register_enum ('App::MathImage::Gtk2::Drawing::Path',
                             App::MathImage::Generator->path_choices);

  Glib::Type->register_enum ('App::MathImage::Gtk2::Drawing::Filters',
                             App::MathImage::Generator->filter_choices);
  %App::MathImage::Gtk2::Drawing::Filters::EnumBits_to_display =
    (All    => __('No Filter'),
     Odd    => __('Odd'),
     Even   => __('Even'),
     Primes => __('Primes'));

  Glib::Type->register_enum ('App::MathImage::Gtk2::Drawing::FigureType',
                             App::MathImage::Generator->figure_choices);
  %App::MathImage::Gtk2::Drawing::FigureType::EnumBits_to_display =
    ('default' => 'Figure');
}

use Glib::Object::Subclass
  'Gtk2::DrawingArea',
  signals => { expose_event  => \&_do_expose,
               size_allocate => \&_do_size_allocate,
               style_set => \&_do_style_set,
               button_press_event => \&_do_button_press,
               scroll_event => \&App::MathImage::Gtk2::Ex::AdjustmentBits::scroll_widget_event_vh,
             },
  properties => [
                 Glib::ParamSpec->enum
                 ('path',
                  'Path type',
                  'Blurb.',
                  'App::MathImage::Gtk2::Drawing::Path',
                  App::MathImage::Generator->default_options->{'path'},
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->scalar
                 ('path-parameters',
                  'Path Parameters',
                  'Blurb.',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->enum
                 ('values',
                  'Values',
                  'Blurb.',
                  'App::MathImage::Gtk2::Drawing::Values',
                  App::MathImage::Generator->default_options->{'values'},
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->scalar
                 ('values-parameters',
                  'Values Parameters',
                  'Blurb.',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->enum
                 ('filter',
                  'Filter',
                  'Blurb.',
                  'App::MathImage::Gtk2::Drawing::Filters',
                  App::MathImage::Generator->default_options->{'filter'},
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->int
                 ('scale',
                  'Scale pixels',
                  'Blurb.',
                  1, POSIX::INT_MAX(),
                  App::MathImage::Generator->default_options->{'scale'},
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->string
                 ('foreground',
                  __('Foreground colour'),
                  'Blurb.',
                  App::MathImage::Generator->default_options->{'foreground'},
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->boolean
                 ('draw-progressive',
                  'Draw Progressive',
                  'Blurb.',
                  1,      # default
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->object
                 ('hadjustment',
                  'Horizontal Adjustment',
                  'Blurb.',
                  'Gtk2::Adjustment',
                  Glib::G_PARAM_READWRITE),
                 Glib::ParamSpec->object
                 ('vadjustment',
                  'Vertical Adjustment',
                  'Blurb.',
                  'Gtk2::Adjustment',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->enum
                 ('figure',
                  'Figure',
                  'Blurb.',
                  'App::MathImage::Gtk2::Drawing::FigureType',
                  'default',
                  Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->add_events (['button-press-mask','button-release-mask']);
  # background pixmap doesn't need double buffering
  $self->set_double_buffered (0);

  $self->{'hadjustment'} = Gtk2::Adjustment->new (0,0,0,0,0,0);
  $self->{'vadjustment'} = Gtk2::Adjustment->new (0,0,0,0,0,0);
  $self->set (hadjustment => $self->{'hadjustment'},
              vadjustment => $self->{'vadjustment'});

  $self->{'path_basis'} = [ _centre_basis($self) ];
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### Drawing SET_PROPERTY: $pname
  ### $newval

  if ($pname ne 'hadjustment' && $pname ne 'vadjustment') {
    delete $self->{'gen_object'};
  }

  my $oldval = $self->get($pname);
  $self->{$pname} = $newval;
  if (defined($oldval) != defined($newval)
      || (defined $oldval && $oldval ne $newval)) {

    if ($pname ne 'draw_progressive') {
      delete $self->{'path_object'};
      delete $self->{'pixmap'};
      $self->queue_draw;
    }
  }

  if ($pname eq 'hadjustment' || $pname eq 'vadjustment') {
    my $adj = $newval;
    Scalar::Util::weaken (my $weak_self = $self);
    $self->{"${pname}_ids"} = $adj && Glib::Ex::SignalIds->new
      ($adj, $adj->signal_connect (value_changed => \&_adjustment_value_changed,
                                   \$weak_self));
    _update_adjustment_extents($self);
  }
  if ($pname eq 'scale' || $pname eq 'path') {
    _update_adjustment_extents($self);
  }

  if ($pname eq 'scale') {
    _update_adjustment_values ($self,
                               $self->allocation->width / $oldval,
                               $self->allocation->height / $oldval,
                               $self->allocation->width / $newval,
                               $self->allocation->height / $newval);
  }

  if ($pname eq 'path' || $pname eq 'path_parameters') {
    my ($x, $y) = _centre_basis($self);
    my ($old_x, $old_y) = @{$self->{'path_basis'}};
    if ($x != $old_x) {
      my $hadj = $self->{'hadjustment'};
      my $width = $self->allocation->width;
      my $scale = $self->get('scale');
      ### new basis hadj...
      ### $x
      ### $old_x
      ### add: ($x-$old_x)*(-$width/$scale/2 - -1/2)
      $hadj->set_value ($hadj->value + ($x-$old_x)*(-$width/$scale/2 - -1/2));
    }
    if ($y != $old_y) {
      my $vadj = $self->{'vadjustment'};
      my $height = $self->allocation->height;
      my $scale = $self->get('scale');
      ### new basis vadj...
      ### $y
      ### $old_y
      ### add: ($y-$old_y)*(-$height/$scale/2 - -1/2)
      $vadj->set_value ($vadj->value + ($y-$old_y)*(-$height/$scale/2 - -1/2));
    }
    $self->{'path_basis'} = [$x,$y];
  }
}
sub _drawable_size_equal {
  my ($d1, $d2) = @_;
  # ### _drawable_size_equal: $d1->get_size, $d2->get_size

  my ($w1, $h1) = $d1->get_size;
  my ($w2, $h2) = $d2->get_size;
  # ### result: ($w1 == $w2 && $h1 == $h2)
  return ($w1 == $w2 && $h1 == $h2);
}

sub _do_style_set {
  my ($self) = @_;
  shift->signal_chain_from_overridden(@_);
  delete $self->{'gen_object'};
}
sub _do_size_allocate {
  my ($self, $alloc) = @_;
  my $old_width = $self->allocation->width;
  my $old_height = $self->allocation->height;

  ### Gtk2-Drawing _do_size_allocate(): $alloc->width."x".$alloc->height
  ### window: $self->window
  ### $old_width
  ### $old_height

  shift->signal_chain_from_overridden(@_);

  delete $self->{'gen_object'};
  _update_adjustment_extents($self);
  my $scale = $self->get('scale');
  _update_adjustment_values ($self,
                             $old_width / $scale,
                             $old_height / $scale,
                             $self->allocation->width / $scale,
                             $self->allocation->height / $scale);
}

sub _update_adjustment_values {
  my ($self, $old_hpage,$old_vpage, $new_hpage,$new_vpage) = @_;
  ### _update_adjustment_values() ...
  {
    my $hadj = $self->{'hadjustment'};
    my $value = $hadj->value;
    my $dec = ($new_hpage - $old_hpage) / 2;
    ### x_negative: $self->x_negative
    unless ($self->x_negative) {
      if ($dec >= 0) {
        # don't float in the air when expand
        if ($value >= -0.5) {
          $dec = min ($value + .5, $dec);
        }
      } else {
        # don't go negative when shrink
        $dec = max ($value + .5, $dec);
      }
    }
    ### hadj value: $value
    ### hadj dec: $dec
    $hadj->set_value ($value - $dec);
  }
  {
    my $vadj = $self->{'vadjustment'};
    my $value = $vadj->value;
    my $dec = ($new_vpage - $old_vpage) / 2;
    my $factor = 1;
    unless ($self->y_negative) {
      if ($value < -0.5) {
        # already negative, stay relative to bottom edge
        $factor = $new_vpage / $old_vpage;
        $dec = 0;
      } elsif ($dec >= 0) {
        if ($value >= -0.5) {
          # don't float in the air when expand
          $dec = min ($value + .5, $dec);
        }
      } else {
        # don't go negative when shrink
        $dec = max (- ($value + .5), $dec);
      }
    }
    ### vadj old page: $old_vpage
    ### vadj new page: $new_vpage
    ### vadj value: $value
    ### vadj dec: $dec
    ### vadj factor: $factor
    $vadj->set_value ($factor*$value - $dec);
  }
}

sub _adjustment_value_changed {
  my ($adj, $ref_weak_self) = @_;
  ### _adjustment_value_changed(): $adj->value
  my $self = $$ref_weak_self || return;
  _update_adjustment_extents($self);
  delete $self->{'pixmap'}; # new image
  $self->queue_draw;
}

sub _do_expose {
  my ($self, $event) = @_;
  ### Drawing _do_expose(): $event->area->values
  ### _pixmap_is_good says: _pixmap_is_good($self)
  #### $self

  $self->pixmap;
  my $win = $self->window;
  Gtk2::Ex::GdkBits::window_clear_region ($win, $event->region);
  if (my $pixmap = $self->{'generator'}->{'pixmap'}) {
    $win->draw_drawable ($self->style->black_gc, $pixmap,
                         $event->area->x,
                         $event->area->y,
                         $event->area->values);
  }
  return Gtk2::EVENT_PROPAGATE;
}

sub pixmap {
  my ($self) = @_;
  ### pixmap()...
  if (! _pixmap_is_good($self)) {
    ### new pixmap...
    delete $self->{'gen_object'};
    $self->start_drawing_window ($self->window);
  }
  return $self->{'pixmap'};
}
sub _pixmap_is_good {
  my ($self) = @_;
  ### _pixmap_is_good() pixmap: $self->{'pixmap'}
  my $pixmap = $self->{'pixmap'};
  return ($pixmap && _drawable_size_equal($pixmap,$self->window));
}

sub gen_object {
  my ($self, %gen_parameters) = @_;
  if (! %gen_parameters && (my $gen_object = $self->{'gen_object'})) {
    return $gen_object;
  }

  ### Drawing create gen_object() ...
  ### values: $self->get('values')

  my (undef, undef, $width, $height) = $self->allocation->values;
  my $background_colorobj = $self->style->bg($self->state);
  my $foreground_colorobj = $self->style->fg($self->state);
  my $undrawnground_colorobj = Gtk2::Gdk::Color->new
    (map {0.8 * $background_colorobj->$_()
            + 0.2 * $foreground_colorobj->$_()}
     'red', 'blue', 'green');

  my $generator_class = delete $gen_parameters{'generator_class'}
    || 'App::MathImage::Gtk2::Generator';
  ### $generator_class

  Module::Load::load ($generator_class);
  my $gen_object = $generator_class->new
    (widget  => $self,
     window  => $self->window,
     gtkmain => $self->get_ancestor('Gtk2::Window'),

     foreground       => $foreground_colorobj->to_string,
     background       => $background_colorobj->to_string,
     undrawnground    => $undrawnground_colorobj->to_string,
     draw_progressive => $self->get('draw-progressive'),

     width           => $width,
     height          => $height,
     step_time       => _IDLE_TIME_SLICE,
     step_figures    => _IDLE_TIME_FIGURES,

     values            => $self->get('values'),
     values_parameters => $self->{'values_parameters'},

     path            => $self->get('path'),
     path_parameters => $self->{'path_parameters'},

     scale           => $self->get('scale'),
     figure          => $self->get('figure'),

     filter          => $self->get('filter'),
     x_left          => $self->{'hadjustment'}->value,
     y_bottom        => $self->{'vadjustment'}->value,

     widgetcursor    => $self->widgetcursor,
     %gen_parameters);

  # print 'gen "widget" isweak ',
  #   Scalar::Util::isweak($gen_object->{'widget'}),"\n";

  if (! %gen_parameters) {
    $self->{'gen_object'} = $gen_object;
  }
  return $gen_object;
}
sub x_negative {
  my ($self) = @_;
  return $self->gen_object->x_negative;
}
sub y_negative {
  my ($self) = @_;
  return $self->gen_object->y_negative;
}

sub widgetcursor {
  my ($self) = @_;
  require Gtk2::Ex::WidgetCursor;
  return ($self->{'widgetcursor'}
          ||= Gtk2::Ex::WidgetCursor->new (widget => $self,
                                           cursor => 'watch'));
}

sub start_drawing_window {
  my ($self, $window) = @_;

  $self->widgetcursor->active(1);
  {
    my $style = $self->style;
    my $background_colorobj = $style->bg($self->state);
    $window->set_background ($background_colorobj);
  }

  my $gen = $self->{'generator'} = $self->gen_object;

  $self->{'path_object'} = $gen->path_object;
  $self->{'affine_object'} = $gen->affine_object;

  if ($self->window && $window == $self->window) {
    $self->{'pixmap'} = $gen->{'pixmap'}; # not if drawing to root window
  }
}

sub pointer_xy_to_image_xyn {
  my ($self, $x, $y) = @_;
  ### pointer_xy_to_image_xyn(): "$x,$y"
  my $affine_object = $self->{'affine_object'} || return;
  my ($px,$py) = $affine_object->clone->invert->transform($x,$y);
  ### $px
  ### $py
  my $path_object = $self->{'path_object'}
    || return ($px, $py);
  if ($path_object->figure eq 'square') {
    $px = POSIX::floor ($px + 0.5);
    $py = POSIX::floor ($py + 0.5);
  }
  return ($px, $py, $path_object->xy_to_n($px,$py));
}

sub centre {
  my ($self) = @_;
  ### Drawing centre()...
  my ($x, $y) = _centre_values($self);
  $self->{'hadjustment'}->set_value ($x);
  $self->{'vadjustment'}->set_value ($y);
}
sub _centre_values {
  my ($self) = @_;
  my ($x, $y) = _centre_basis($self);
  ### _centre_values() to basis: "$x,$y"
  my $scale = $self->get('scale');
  my (undef, undef, $width, $height) = $self->allocation->values;
  return (($x ? -$width/$scale/2 : -1/2),
          ($y ? -$height/2/$scale : -1/2));
}

sub _centre_basis {
  my ($self) = @_;
  my $path = $self->get('path') || '';
  ### _centre_basis(): $path
  my $path_object = $self->gen_object->path_object;
  return ($path_object->class_x_negative,
          $path_object->class_y_negative);
}

# 'button-press-event' class closure
sub _do_button_press {
  my ($self, $event) = @_;
  ### Drawing _do_button_press(): $event->button
  my $button = $event->button;
  if ($button == 1) {
    _do_start_drag ($self, $button, $event);
  }
  return shift->signal_chain_from_overridden(@_);
}
sub _do_start_drag {
  my ($self, $button, $event) = @_;
  my $dragger = ($self->{'dragger'} ||= do {
    require Gtk2::Ex::Dragger;
    Gtk2::Ex::Dragger->new (widget => $self,
                            hadjustment => $self->{'hadjustment'},
                            vadjustment => $self->{'vadjustment'},
                            vinverted   => 1,
                            cursor      => 'fleur')
    });
  $dragger->start ($event);
}

sub _update_adjustment_extents {
  my ($self) = @_;
  my (undef, undef, $width, $height) = $self->allocation->values;
  my $scale = $self->get('scale');
  ### _update_adjustment_extents()...
  ### $width
  ### $height
  ### $scale
  {
    my $hadj = $self->{'hadjustment'};
    my $page = $width / $scale;
    $hadj->set (page_size      => $page,
                page_increment => $page * .9,
                step_increment => $page * .1,
                upper          => max ($hadj->upper, $hadj->value + 2.5*$page),
                lower          => min ($hadj->lower, $hadj->value - 1.5*$page),
               );
    ### hadj: $hadj->value.' of '.$hadj->lower.' to '.$hadj->upper.' page='.$hadj->page_size
  }
  {
    my $vadj = $self->{'vadjustment'};
    my $page = $height / $scale;
    $vadj->set (page_size      => $page,
                page_increment => $page * .9,
                step_increment => $page * .1,
                upper          => max ($vadj->upper, $vadj->value + 2.5*$page),
                lower          => min ($vadj->lower, $vadj->value - 1.5*$page),
               );
    ### vadj: $vadj->value.' of '.$vadj->lower.' to '.$vadj->upper
  }
  #   my $affine_object = $self->{'affine_object'};
  #   my ($value,       undef) = $affine_object->untransform(0,0);
  #   my ($value_upper, undef) = $affine_object->untransform($width,0);
  #   my $page_size = $value_upper - $value;
  #   ### hadj: "$value to $value_upper"
  #   $hadj->set (lower     => min (0, $value - 1.5 * $page_size),
  #               upper     => max (0, $value_upper + 1.5 * $page_size),
  #               page_size => $page_size);
  # }
}

#------------------------------------------------------------------------------
# generic

sub draw_text_centred {
  my ($widget, $drawable, $str) = @_;
  ### draw_text_centred(): $str
  ### $drawable
  my ($width, $height) = $drawable->get_size;
  my $layout = $widget->create_pango_layout ($str);
  $layout->set_wrap ('word-char');
  $layout->set_width ($width * Gtk2::Pango::PANGO_SCALE());
  my ($str_width, $str_height) = $layout->get_pixel_size;
  my $x = max (0, int (($width  - $str_width)  / 2));
  my $y = max (0, int (($height - $str_height) / 2));

  ### paint: "$x,$y  $str_width x $str_height of $width x $height"
  my $style = $widget->get_style;
  $style->paint_layout ($drawable,
                        $widget->state,
                        0, # use foreground gc
                        undef,
                        $widget,
                        'centred-text',
                        $x, $y, $layout);
}

1;
