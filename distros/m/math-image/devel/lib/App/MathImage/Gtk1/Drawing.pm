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


package App::MathImage::Gtk1::Drawing;
use 5.004;
use strict;
use Carp;
use List::Util qw(min max);
use POSIX ();
use Scalar::Util;
use Module::Load;
use App::MathImage::Generator;
use App::MathImage::Gtk1::Ex::SignalIds;

use vars '$VERSION','@ISA';
$VERSION = 110;

# use Locale::TextDomain ('App-MathImage');

# use Glib::Ex::SourceIds;
# use Gtk1::Ex::SyncCall 12; # v.12 workaround gtk 2.12 bug
# use Gtk1::Ex::GdkBits 23; # v.23 for window_clear_region()
# 
# use App::MathImage::Gtk1::Drawing::Values;
# use App::MathImage::Gtk1::Ex::AdjustmentBits;

# uncomment this to run the ### lines
#use Smart::Comments '###';

use constant _IDLE_TIME_SLICE => 0.25;  # seconds
use constant _IDLE_TIME_FIGURES => 1000;  # drawing requests

use constant::defer init => sub {
  ### Drawing init(): @_
  require Gtk;
  Gtk->init;
  @ISA = ('Gtk::DrawingArea');
  Gtk::DrawingArea->register_subtype(__PACKAGE__);
  return undef;
};
sub new {
  ### DrawingDialog new(): @_
  init();
  return Gtk::Widget->new(@_);
}

sub GTK_CLASS_INIT {
  my ($class) = @_;
  ### Drawing GTK_CLASS_INIT() ...
  $class->add_arg_type ('draw-progressive', 'gboolean', 3); #R/W
  $class->add_arg_type ('scale', 'gint', 3); #R/W
  $class->add_arg_type ('values', 'GtkString', 3); #R/W
  $class->add_arg_type ('path', 'GtkString', 3); #R/W
  $class->add_arg_type ('figure', 'GtkString', 3); #R/W
  $class->add_arg_type ('hadjustment', 'GtkObject', 3); #R/W
  $class->add_arg_type ('vadjustment', 'GtkObject', 3); #R/W
}

sub GTK_OBJECT_INIT {
  my ($self) = @_;
  ### Drawing GTK_OBJECT_INIT() ...

  # defaults
  my $default_options = App::MathImage::Generator->default_options;
  $self->{'draw-progressive'} = 1;
  $self->{'scale'} = 20;
  $self->{'figure'} = 'default';
  $self->{'values'} = $default_options->{'values'};
  $self->{'path'} = $default_options->{'path'};
  $self->{'values-parameters'} = {};
  $self->{'path-parameters'} = {};

  $self->signal_connect (expose_event  => \&_do_expose);
  $self->signal_connect (size_allocate => \&_do_size_allocate);

  Scalar::Util::weaken (my $weak_self = $self);
  {
    my $hadj = Gtk::Adjustment->new (0,0,0,0,0,0);
    $hadj->signal_connect (value_changed => \&_adjustment_value_changed,
                           \$weak_self);
    $self->{'hadjustment'} = $hadj;
  }
  {
    my $vadj = Gtk::Adjustment->new (0,0,0,0,0,0);
    $vadj->signal_connect (value_changed => \&_adjustment_value_changed,
                           \$weak_self);
    $self->{'vadjustment'} = $vadj;
  }

  $self->{'path_basis'} = [ _centre_basis($self) ];
}


sub GTK_OBJECT_SET_ARG {
  my ($self,$arg,$id, $value) = @_;
  ### Drawing GTK_OBJECT_SET_ARG(): "$arg, $id to $value"
  $self->{$arg} = $value;
  if ($arg eq 'values'
      || $arg eq 'path'
      || $arg eq 'scale'
      || $arg eq 'figure') {
    # redraw
    delete $self->{'pixmap'};
    $self->queue_draw;
  }
}
sub GTK_OBJECT_GET_ARG {
  my ($self,$arg,$id) = @_;
  ### Drawing GTK_OBJECT_GET_ARG(): "$arg, $id is ".$self->{$arg}
  return $self->{$arg};
}


# BEGIN {
#   Glib::Type->register_enum ('App::MathImage::Gtk1::Drawing::Filters',
#                              'All', 'Odd', 'Even', 'Primes');
#   %App::MathImage::Gtk1::Drawing::Filters::EnumBits_to_display =
#     (All    => __('No Filter'),
#      Odd    => __('Odd'),
#      Even   => __('Even'),
#      Primes => __('Primes'));
# }

# use Glib::Object::Subclass
#   'Gtk1::DrawingArea',
#   signals => { button_press_event => \&_do_button_press,
#                scroll_event => \&App::MathImage::Gtk1::Ex::AdjustmentBits::scroll_widget_event_vh,
#              },
#   properties => [
#                  Glib::ParamSpec->enum
#                  ('filter',
#                   'Filter',
#                   'Blurb.',
#                   'App::MathImage::Gtk1::Drawing::Filters',
#                   App::MathImage::Generator->default_options->{'filter'},
#                   Glib::G_PARAM_READWRITE),
# 
#                  Glib::ParamSpec->string
#                  ('foreground',
#                   __('Foreground colour'),
#                   'Blurb.',
#                   App::MathImage::Generator->default_options->{'foreground'},
#                   Glib::G_PARAM_READWRITE),
#
# sub INIT_INSTANCE {
#   my ($self) = @_;
#   $self->add_events (['button-press-mask','button-release-mask']);
# 
# }

# sub SET_PROPERTY {
#   my ($self, $pspec, $newval) = @_;
#   my $pname = $pspec->get_name;
#   ### Drawing SET_PROPERTY: $pname
#   ### $newval
# 
#   my $oldval = $self->get($pname);
#   $self->{$pname} = $newval;
#   if (defined($oldval) != defined($newval)
#       || (defined $oldval && $oldval ne $newval)) {
# 
#     if ($pname ne 'draw-progressive') {
#       delete $self->{'path_object'};
#       delete $self->{'pixmap'};
#       $self->queue_draw;
#     }
#   }
# 
#   if ($pname eq 'hadjustment' || $pname eq 'vadjustment') {
#     my $adj = $newval;
#     $self->{"${pname}_ids"} = $adj && App::MathImage::Gtk1::Ex::SignalIds->new
#       ($adj, );
#     _update_adjustment_extents($self);
#   }
#   if ($pname eq 'scale' || $pname eq 'path') {
#     _update_adjustment_extents($self);
#   }
# 
#   if ($pname eq 'scale') {
#     _update_adjustment_values ($self,
#                                $self->allocation->[2] / $oldval, # width
#                                $self->allocation->[3] / $oldval, # height
#                                $self->allocation->[2] / $newval, # width
#                                $self->allocation->[3] / $newval); # height
#   }
# 
#   if ($pname eq 'path' || $pname eq 'path_parameters') {
#     my ($x, $y) = _centre_basis($self);
#     my ($old_x, $old_y) = @{$self->{'path_basis'}};
#     if ($x != $old_x) {
#       my $hadj = $self->{'hadjustment'};
#       my $width = $self->allocation->[2];
#       my $scale = $self->get('scale');
#       ### new basis hadj...
#       ### $x
#       ### $old_x
#       ### add: ($x-$old_x)*(-$width/$scale/2 - -1/2)
#       $hadj->set_value ($hadj->value + ($x-$old_x)*(-$width/$scale/2 - -1/2));
#     }
#     if ($y != $old_y) {
#       my $vadj = $self->{'vadjustment'};
#       my $height = $self->allocation->height;
#       my $scale = $self->get('scale');
#       ### new basis vadj...
#       ### $y
#       ### $old_y
#       ### add: ($y-$old_y)*(-$height/$scale/2 - -1/2)
#       $vadj->set_value ($vadj->value + ($y-$old_y)*(-$height/$scale/2 - -1/2));
#     }
#     $self->{'path_basis'} = [$x,$y];
#   }
# }

sub _drawable_size_equal {
  my ($d1, $d2) = @_;
  ### _drawable_size_equal: $d1->get_size, $d2->get_size

  my ($h1, $w1) = $d1->get_size;
  my ($h2, $w2) = $d2->get_size;
  # ### result: ($w1 == $w2 && $h1 == $h2)
  return ($w1 == $w2 && $h1 == $h2);
}

sub _do_size_allocate {
  my ($self, $alloc) = @_;
  ### Drawing _do_size_allocate(): "$self", $alloc
  ### cf allocation: $self->allocation

  # # my $old_width = $self->allocation->width;
  # # my $old_height = $self->allocation->height;
  # ### _do_size_allocate(): $alloc->width."x".$alloc->height
  # ### $old_width
  # ### $old_height

  # _update_adjustment_extents($self);
  my $scale = $self->get('scale');
  # _update_adjustment_values ($self,
  #                            $old_width / $scale,
  #                            $old_height / $scale,
  #                            $self->allocation->width / $scale,
  #                            $self->allocation->height / $scale);
  ### _do_size_allocate() done ...
}

sub _update_adjustment_values {
  my ($self, $old_hpage,$old_vpage, $new_hpage,$new_vpage) = @_;
  {
    my $hadj = $self->{'hadjustment'};
    my $value = $hadj->value;
    my $dec = ($new_hpage - $old_hpage) / 2;
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
  ### Drawing _do_expose(): $event
  ### _pixmap_is_good says: _pixmap_is_good($self)
  #### $self
  my $win = $self->window;
  $self->pixmap;
  $win->clear_area (@{$event->{'area'}});
  if (my $pixmap = $self->{'generator'}->{'pixmap'}) {
    $win->draw_pixmap ($self->style->black_gc, $pixmap,
                       0,0, @{$event->{'area'}});
  }
  return 0;  # propagate
}
sub _window_clear_region {
  my ($win, $region) = @_;
  foreach my $rect ($region->get_rectangles) {
    $win->clear_area ($rect->values);
  }
}

sub _pixmap_is_good {
  my ($self) = @_;
  ### _pixmap_is_good() pixmap: $self->{'pixmap'}
  my $pixmap = $self->{'pixmap'};
  return ($pixmap && _drawable_size_equal($pixmap,$self->window));
}

sub pixmap {
  my ($self) = @_;
  ### pixmap()...
  if (! _pixmap_is_good($self)) {
    ### new pixmap...
    $self->start_drawing_window ($self->window);
  }
  return $self->{'pixmap'};
}

sub gen_object {
  my ($self, %gen_parameters) = @_;
  my (undef, undef, $width, $height) = @{$self->allocation};
  my $background_colorobj = $self->style->bg($self->state);
  my $foreground_colorobj = $self->style->fg($self->state);

  # towards foreground a bit
  my $undrawnground_colorobj = _color_new_rgb
    (map {0.8 * $background_colorobj->{$_}
            + 0.2 * $foreground_colorobj->{$_}}
     'red', 'blue', 'green');

  my $generator_class = delete $gen_parameters{'generator_class'}
    || 'App::MathImage::Generator';
  ### $generator_class
  ### draw-progressive: $self->get('draw-progressive')

  # FIXME: this provokes some warnings ...
  my $gtkmain = $self->get_ancestor('Gtk::Window');
  ### x_left:   $self->{'hadjustment'}->value
  ### y_bottom: $self->{'vadjustment'}->value

  Module::Load::load ($generator_class);
  return $generator_class->new
    (widget  => $self,
     window  => $self->window,
     gtkmain => $gtkmain,

     foreground       => _colorobj_to_string($foreground_colorobj),
     background       => _colorobj_to_string($background_colorobj),
     undrawnground    => _colorobj_to_string($undrawnground_colorobj),
     draw_progressive => $self->get('draw-progressive'),

     width           => $width,
     height          => $height,
     step_time       => _IDLE_TIME_SLICE,
     step_figures    => _IDLE_TIME_FIGURES,

     values          => $self->get('values'),
     values_parameters => $self->{'values-parameters'},

     path            => $self->get('path'),
     path_parameters => {
                         %{$self->{'path-parameters'} || {}},
                         width           => $width,
                         height          => $height,
                        },

     scale           => $self->get('scale'),
     figure          => $self->get('figure'),
     
     # filter          => $self->get('filter'),
     x_left          => $self->{'hadjustment'}->value,
     y_bottom        => $self->{'vadjustment'}->value,

     # widgetcursor    => $self->widgetcursor,
     %gen_parameters);
}
sub x_negative {
  my ($self) = @_;
  return $self->gen_object->x_negative;
}
sub y_negative {
  my ($self) = @_;
  return $self->gen_object->y_negative;
}

sub _colorobj_to_string {
  my ($color) = @_;
# ### _colorobj_to_string(): $color
  return sprintf '#%04X%04X%04X',
    $color->{'red'},
      $color->{'green'},
        $color->{'blue'};
}
sub _color_new_rgb {
  my ($red, $green, $blue) = @_;
  return Gtk::Gdk::Color->parse_color (sprintf '#%04X%04X%04X',
                                       $red, $green, $blue);
}

# sub widgetcursor {
#   my ($self) = @_;
#   require Gtk1::Ex::WidgetCursor;
#   return ($self->{'widgetcursor'}
#           ||= Gtk1::Ex::WidgetCursor->new (widget => $self,
#                                            cursor => 'watch'));
# }

sub start_drawing_window {
  my ($self, $window) = @_;

  # $self->widgetcursor->active(1);

  my $style = $self->style;
  my $background_colorobj = $style->bg($self->state);
  $window->set_background ($background_colorobj);

  my $gen = $self->{'generator'}
    = $self->gen_object (generator_class => 'App::MathImage::Gtk1::Generator');

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
  my $path_object =  $self->{'path_object'}
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
  ### hadj: $self->{'hadjustment'}->value
  ### vadj: $self->{'vadjustment'}->value
  my ($x, $y) = _centre_values($self);
  $self->{'hadjustment'}->set_value ($self->{'hadjustment'}->value + 100); #  ($x + 100);
  $self->{'vadjustment'}->set_value ($y);
  ### hadj: $self->{'hadjustment'}->value
  ### vadj: $self->{'vadjustment'}->value
}
sub _centre_values {
  my ($self) = @_;
  my ($x, $y) = _centre_basis($self);
  my $scale = $self->get('scale');
  my (undef, undef, $width, $height) = @{$self->allocation};
  return (($x ? -$width/$scale/2 : -1/2),
          ($y ? -$height/2/$scale : -1/2));
}
sub _centre_basis {
  my ($self) = @_;
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
    require Gtk::Ex::Dragger;
    Gtk::Ex::Dragger->new (widget => $self,
                            hadjustment => $self->{'hadjustment'},
                            vadjustment => $self->{'vadjustment'},
                            vinverted   => 1,
                            cursor      => 'fleur')
    });
  $dragger->start ($event);
}

sub _update_adjustment_extents {
  my ($self) = @_;
  my (undef, undef, $width, $height) = @{$self->allocation};
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
  my ($win_height, $win_width) = $drawable->get_size;

  my $style = $widget->get_style;
  my $font = $style->font;
  ### extents: $font->text_extents ($str, length($str))
  my ($lbearing, $rbearing, $width, $ascent, $descent)
    = $font->text_extents ($str, length($str));
  my $x = max (0, int(($win_width - $width)/2));
  my $y = max ($ascent, int(($win_height - $ascent - $descent)/2 + $ascent));

  # or for multiple lines $font->ascent+$font->descent spacing ...

  ### text: "$x,$y  $width x $ascent of $win_width x $win_height"
  $drawable->draw_text ($font, $style->fg_gc($widget->state),
                        $x, $y, $str, length($str))
}

1;
