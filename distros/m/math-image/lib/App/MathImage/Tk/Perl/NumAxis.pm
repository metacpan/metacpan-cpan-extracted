# Copyright 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.

package App::MathImage::Tk::Perl::NumAxis;
use 5.008;
use strict;
use warnings;
use Tk;
use List::Util qw(min max);
use Math::Round;
use POSIX qw(floor ceil);

use base 'Tk::Derived', 'Tk::Canvas';
Tk::Widget->Construct('AppMathImageTkPerlNumAxis');

our $VERSION = 110;


# uncomment this to run the ### lines
#use Smart::Comments;


sub ClassInit {
  my ($class, $mw) = @_;
  ### ClassInit(): $class
  $class->SUPER::ClassInit($mw);

  # event handlers for all instances
  $mw->bind($class,'<Configure>',  \&_do_resized);
  $mw->bind($class,'<Button-1>',   ['DragStart', Ev('x'), Ev('y')]);
  $mw->bind($class,'<B1-Motion>',  ['DragMotion', Ev('x'), Ev('y')]);
  $mw->bind($class,'<MouseWheel>', ['MouseWheel', Ev('delta'), Ev('s')]);
  $mw->bind($class,'<Button-4>',   ['MouseWheel', 120, Ev('s')]);
  $mw->bind($class,'<Button-5>',   ['MouseWheel', -120, Ev('s')]);
}

sub Populate {
  my ($self, $args) = @_;
  ### Drawing Populate(): $args

  $self->ConfigSpecs('-min_decimals' => [ 'METHOD',
                                          'TkPerlNumAxis',
                                          'TkPerlNumAxis',
                                          0 ]);
  $self->ConfigSpecs('-orientation' => [ 'METHOD',
                                         'TkPerlNumAxis',
                                         'TkPerlNumAxis',
                                         'vertical' ]);
  $self->ConfigSpecs('-inverted' => [ 'PASSIVE',
                                      'TkPerlNumAxis',
                                      'TkPerlNumAxis',
                                      0 ]);
  $self->ConfigSpecs('-number_to_text' => [ 'METHOD',
                                            'TkPerlNumAxis',
                                            'TkPerlNumAxis',
                                            'default_number_to_text' ]);

  $self->ConfigSpecs('-lower' => [ 'PASSIVE',
                                   'TkPerlNumAxis',
                                   'TkPerlNumAxis',
                                   0 ]);
  $self->ConfigSpecs('-page_size' => [ 'PASSIVE',
                                       'TkPerlNumAxis',
                                       'TkPerlNumAxis',
                                       0 ]);

  my %args = (-background         => 'black',
              -foreground         => 'white',
              -activebackground   => 'black',
              -activeforeground   => 'white',
              -disabledforeground => 'white',
              -borderwidth        => 0, # default

              # must initial -image so that Tk::Label -width and -height are
              # interpreted as pixels, not lines/columns
              -image   => $self->Photo (-width => 1, -height => 1),
              -width   => 1, # desired size any, not from -image
              -height  => 1,

              %$args);
  $self->SUPER::Populate(\%args);
  $self->{'decided_done_for'} = '';
}

               # 'number-to-text' =>
               # { param_types => ['Glib::Double','Glib::Int'],
               #   return_type => 'Glib::String',
               #   flags       => ['run-last'],
               #   accumulator => \&Glib::Ex::SignalBits::accumulator_first_defined,
               #   class_closure => \&_do_number_to_text },



# as fraction of digit width
# these not documented, could be properties or style properties
use constant { TICK_WIDTH_FRAC   => 0.8,
               TICK_GAP_FRAC     => 0.5,
               TICK_HEIGHT_FRAC  => 0.4,
               TICK_VGAP_FRAC    => 0.1,
             };
# right-margin 0.2    between number and right edge of window

sub _do_resized {
  my ($self) = @_;
  ### _do_resized() ...
  $self->queue_redraw();
}

sub queue_redraw {
  my ($self) = @_;
  ### queue_redraw() ...
  $self->{'update_id'} ||= $self->afterIdle(sub {
                                              delete $self->{'update_id'};
                                              _do_redraw($self);
                                            });
}

my %wh = (horizontal => 'width',
          vertical   => 'height');

sub _do_redraw {
  my ($self) = @_;
  ### Drawing _do_redraw(): $self
  if (my $id = delete $self->{'update_id'}) { $id->cancel; }

  my $orientation = {'-orientation'};
  if ($orientation eq 'horizontal') {
    $self->configure (-width => 1,
                      -height => _decide_height($self));
  } else {
    $self->configure (-width => _decide_width($self),
                      -height => 1);
  }

  my $borderwidth = $self->cget('-borderwidth');
  my $width = $self->width - 2*$borderwidth;
  my $height = $self->height - 2*$borderwidth;
  my $font = _font($self);

  # for (;;) {
  #   my $item = pop @textitems
  #     || $self->createText(0,0, -anchor => 'w');
  #   $self->itemconfigure($item, -text => 'foo');
  #   $self->move($item, $borderwidth, $borderwidth + 20);
  #   last;
  # }

  my $page_size = $self->cget('-page_size') || do {
    ### zero height page, no draw ...
    return;
  };

  my $lo = $self->cget('-lower');
  my ($unit, $unit_decimals) = _decide_unit ($self, $lo);
  ### $unit
  ### $unit_decimals
  if ($unit == 0) {
    ### unit zero, no draw ...
    return;
  }
  my $hi = $lo + $page_size;
  ### $lo
  ### $hi

  my $state      = $self->cget('-state');
  my $decimals   = $self->cget('-min_decimals');
  my $win_pixels = ($orientation eq 'vertical' ? $height : $width);

  my $factor    = $win_pixels / $page_size;
  my $offset    = 0;
  if ($self->{'inverted'}) {
    $factor = -$factor;
    $offset = $win_pixels;
    ### invert
    ### $factor
    ### $offset
  }
  $offset += -$lo * $factor;

  my $digit_height  = $self->{'digit_height'};
  $decimals = max ($decimals, $unit_decimals);
  my $widen = $digit_height / abs($factor);
  $lo -= $widen;
  $hi += $widen;

  ### $win_pixels
  ### $factor
  ### digit_height pixels: $digit_height
  ### which is widen value: $widen
  ### widen to: "lo=$lo hi=$hi"
  ### $unit
  ### $decimals

  my $transform   = $self->{'transform'}   || \&identity;
  my $untransform = $self->{'untransform'} || \&identity;
  my $number_to_text = $self->{'-number_to_text'};

  $lo = $transform->($lo);
  $hi = $transform->($hi);
  my $n = Math::Round::nhimult ($unit, $lo);
  ### loop: "$lo to $hi, starting $n"


  my @textitems = $self->find('withtag','text');
  my @tickitems = $self->find('withtag','tick');

  if ($orientation eq 'horizontal') {
    my $decided_height = _decide_height($self);
    my $tick_height = ceil (TICK_HEIGHT_FRAC * $digit_height);
    my $tick_y = $borderwidth;
    my $text_y = $tick_height + ceil (TICK_VGAP_FRAC * $digit_height);

    for ( ; $n <= $hi; $n += $unit) {
      my $str = $self->$number_to_text($n,$decimals);
      my ($str_width,$str_height) = widget_font_string_size($self,$font,$str);

      my $u = $untransform->($n);
      my $x = floor ($factor * $u + $offset);
      ### $x

      {
        my $item = pop @textitems || $self->createText(0, $text_y,
                                                       -anchor => 'n',
                                                       -tag => 'text');
        $self->itemconfigure($item, -text => $str);
        canvasitem_move_to_x($self,$item,$x);
      }
      {
        my @tickitems;
        my $item = pop @tickitems
          || $self->createLine($tick_y,0, 0,$tick_y+$tick_height,
                               -tag => 'tick');
        canvasitem_move_to_x($self,$item,$x);
      }

      if ($x >= 0 && $x < $win_pixels  # only values more than half in window
          && ($str_height += $text_y) > $decided_height) {
        ### draw is higher than decided_height: "str=$str, height=$str_height cf decided_height=$decided_height"
        $decided_height = $self->{'decided_height'} = $str_height;
        # $self->queue_resize;
      }
    }

  } else {
    ### vertical ...
    my $decided_width = _decide_width($self);
    my $digit_width = $self->{'digit_width'};
    my $tick_width = ceil (TICK_WIDTH_FRAC * $digit_width);
    my $tick_x = $borderwidth;
    my $text_x = $tick_x + $tick_width + ceil (TICK_GAP_FRAC * $digit_width);

    for ( ; $n <= $hi; $n += $unit) {
      my $str = $self->$number_to_text($n,$decimals);
      my ($str_width,$str_height) = widget_font_string_size($self,$font,$str);

      my $u = $untransform->($n);
      my $y = $borderwidth + floor ($factor * $u + $offset);

      ### $str
      ### $y

      my $text_y = $y - int ($str_height/2); # top of text
      if ($text_y >= $win_pixels || $y + $str_height <= 0) {
        ### outside window, skip
        next;
      }


      {
        my $item = pop @textitems || $self->createText($text_x, 0,
                                                       -anchor => 'w',
                                                       -tag => 'text');
        $self->itemconfigure($item, -text => $str);
        canvasitem_move_to_y($self,$item,$y);
      }
      {
        my @tickitems;
        my $item = pop @tickitems
          || $self->createLine($tick_x,0, $tick_x+$tick_width,0,
                               -tag => 'tick');
        canvasitem_move_to_y($self,$item,$y);
      }
      if ($y >= 0 && $y < $win_pixels  # only values more than half in window
          && ($str_width += $text_x) > $decided_width) {
        ### draw is wider than decided_width: "str=$str, width=$str_width cf decided_width=$decided_width"
        $decided_width = $self->{'decided_width'} = $str_width;
        #        $self->queue_redraw;
      }
    }
  }

  foreach (@textitems) {
    $self->itemconfigure($_, -text => 'fjdsk');
  }
  foreach (@textitems, @tickitems) {
    $self->delete($_);
  }
  # $self->delete(@textitems, @tickitems);
}

sub canvasitem_move_to_x {
  my ($canvas, $item, $x) = @_;
  my ($old_x) = $canvas->coords($item);
  $canvas->move($item, $x-$old_x, 0);
}
sub canvasitem_move_to_y {
  my ($canvas, $item, $y) = @_;
  my (undef,$old_y) = $canvas->coords($item);
  $canvas->move($item, 0, $y-$old_y);
}

sub orientation {
  my ($self, $newval) = @_;
  if (@_ > 1) {
    if ($self->{'-orientation'} ne $newval) {
      $self->{'-orientation'} = $newval;
      $self->delete('text','tick');
      $self->{'decided_done_for'} = '';
      $self->queue_redraw;
    }
  }
  return $self->{'-orientation'};
}
sub min_decimals {
  my ($self, $newval) = @_;
  if (@_ > 1) {
    if ($self->{'-min_decimals'} != $newval) {
      $self->{'-min_decimals'} = $newval;
      $self->{'decided_done_for'} = '';
      $self->queue_redraw;
    }
  }
  return $self->{'-min_decimals'};
}

#------------------------------------------------------------------------------
# number_to_text

sub number_to_text {
  my ($self, $newval) = @_;
  if (@_ > 1) {
    $self->{'-number_to_text'} = $newval;
    $self->{'decided_done_for'} = '';
    $self->queue_redraw;
  }
  return $self->{'-number_to_text'};
}
sub default_number_to_text {
  my ($self, $number, $decimals) = @_;
  return sprintf ('%.*f', $decimals, $number);
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

  $self->configure (-lower => int($self->cget('-lower')
                                  + $self->cget('-page_size') * $frac));
  $self->queue_redraw;
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
    my $orientation = {'-orientation'};
    my $delta = ($orientation eq 'horizontal'
                 ? $x - $self->{'drag_x'}
                 : $self->{'drag_y'} - $y);
    $self->{'drag_x'} = $x;
    $self->{'drag_y'} = $y;

    if ($self->cget('-inverted')) {
      $delta = -$delta;
    }
    $self->configure (-lower => int($self->cget('-lower') + $delta));
    $self->queue_redraw;
  }
}

#------------------------------------------------------------------------------

sub _decide_width {
  my ($self) = @_;
  ### NumAxis _decide_width() ...

  my $lower = $self->cget('-lower');
  my $page_size = $self->cget('-page_size');
  my $for = "$lower,$page_size";
  if ($self->{'decided_done_for'} eq $for) {
    return $self->{'decided_width'};
  }

  ### old decided width: $self->{'decided_width'}
  ### was for: $self->{'decided_done_for'}
  ### now for: $for
  $self->{'decided_done_for'} = $for;

  my $font = _font($self);
  my $decimals = $self->min_decimals();
  my $digit_width = $self->{'digit_width'};
  my $width = $digit_width * $decimals;

  my ($unit, $unit_decimals) = _decide_unit ($self, $lower);
  ### $unit
  ### $unit_decimals
  $decimals = max ($decimals, $unit_decimals);
  my $transform = $self->{'transform'} || \&identity;
  my $number_to_text = $self->{'-number_to_text'};

  foreach my $un ($lower,
                  $lower + $page_size) {
    my $n = $transform->($un);
    # increase $n to 99.999 etc per its integer part and $decimals
    $n = ($n < 0 ? '-' : '')
      . ('9' x _num_integer_digits($n))
        . '.'
          . ('9' x $decimals);
    my $str = $self->$number_to_text($n, $decimals);
    $width = max ($width, $self->fontMeasure($font, $str));
    ### this str: $str
    ### gives width pixels: $width
  }

  $width += ceil (TICK_WIDTH_FRAC * $digit_width)
    + ceil (TICK_GAP_FRAC * $digit_width);

  ### tick width: ceil (TICK_WIDTH_FRAC * $digit_width)
  ### tick gap:   ceil (TICK_GAP_FRAC * $digit_width)
  ### _decide_width() result: $width

  return ($self->{'decided_width'} = $width);
}

sub _decide_height {
  my ($self) = @_;

  if ($self->{'decided_done_for'} eq '1') {
    return $self->{'decided_height'};
  }
  $self->{'decided_done_for'} = 1;

  ### _decide_height() ...

  my $font = _font($self);
  my $decimals = $self->min_decimals();
  my $transform = $self->{'transform'} || \&identity;
  my $digit_height = $self->{'digit_height'};

  my $lower = $self->cget('-lower');
  my $page_size = $self->cget('-page_size');
  my $number_to_text = $self->{'-number_to_text'};

  my $height = $digit_height;
  foreach my $un ($lower, $lower + $page_size) {
    my $n = $transform->($un);
    my $str = $self->$number_to_text($n, $decimals);
    my $str_height = widget_font_str_height($str);
    $height = max ($height, $str_height);
    ### this str: $str
    ### this height: $str_height
    ### gives height pixels: $height
  }
  $height += ceil(TICK_HEIGHT_FRAC * $digit_height)
    + ceil(TICK_VGAP_FRAC * $digit_height);

  ### tick height: ceil (TICK_HEIGHT_FRAC * $digit_height)
  ### tick vgap:   ceil (TICK_VGAP_FRAC * $digit_height)
  ### _decide_height() result: $height
  return ($self->{'decided_height'} = $height);
}

# return ($step, $decimals)
sub _decide_unit {
  my ($self, $value) = @_;
  ### _decide_unit(): "value=$value"

  my $page_size = $self->cget('-page_size') || do {
    ### zero height page, no draw ...
    return;
  };
  my $lower = $self->cget('-lower');

  my $transform = $self->{'transform'} || \&identity;
  my $min_decimals = $self->min_decimals();
  my $number_to_text = $self->{'-number_to_text'};

  ### $lower
  ### $page_size
  ### $min_decimals

  my $font = _font($self);
  my $str_width = 0;
  my $str_height = 0;
  foreach my $n ($lower + 0.05 * $page_size,
                 $lower + 0.95 * $page_size) {
    my $str = $self->$number_to_text($n, $min_decimals);
    my ($this_width, $this_height)
      = widget_font_string_size($self, $font, $str);
    $str_width = max ($str_width, $this_width);
    $str_height = max ($str_height, $this_height);
  }

  my $orientation = {'-orientation'};
  if ($orientation eq 'horizontal') {
    my $win_width = $self->width;
    for (;;) {
      my $untrans_min_step = 2.0 * $page_size * $str_width / $win_width;
      ### page_size: $page_size
      ### $win_width
      ### $str_width
      ### $untrans_min_step

      my $low_step =  abs ($transform->($value)
                           - $transform->($value + $untrans_min_step));
      my $high_step = abs ($transform->($value + $page_size)
                           - $transform->($value + $page_size
                                          - $untrans_min_step));
      ### $low_step
      ### $high_step
      my ($unit, $decimals) = round_up_2_5_pow_10 (max ($low_step, $high_step));
      if ($decimals <= $min_decimals) {
        return ($unit, $decimals);
      }
      $min_decimals = $decimals;
    }
  } else {
    my $win_height = $self->height;
    my $untrans_min_step = 2.0 * $page_size * $str_height / $win_height;
    ### page_size: $page_size
    ### win_height: $win_height
    ### $str_height
    ### $untrans_min_step
    my $low_step =  abs ($transform->($value)
                         - $transform->($value + $untrans_min_step));
    my $high_step = abs ($transform->($value + $page_size)
                         - $transform->($value + $page_size
                                        - $untrans_min_step));
    ### $low_step
    ### $high_step
    return round_up_2_5_pow_10 (max ($low_step, $high_step));
  }
}

sub _font {
  my ($self) = @_;
  return ($self->{'font'} ||= do {
    my $item = $self->createText(0,0);
    my $font = $self->itemcget($item,'-font');
    $self->delete($item);
    ($self->{'digit_width'}, $self->{'digit_height'})
      = widget_font_digit_size($self,$font);
    $font
  });
}


#------------------------------------------------------------------------------
# mostly generic

sub identity {
  return $_[0];
}

# Return ($digit_width, $digit_height) which is the size in pixels of a
# digit in the given $widget and $font.
#
sub widget_font_digit_size {
  my ($widget,$font) = @_;
  return (max (map {$widget->fontMeasure($font,$_)} 0 .. 9),
          $widget->fontMetrics($font,'-ascent')
          + $widget->fontMetrics($font,'-descent'));
}

sub widget_font_string_height {
  my ($widget,$font,$str) = @_;
  my $num_newlines = ($str =~ tr/\n/\n/);
  return $widget->fontMetrics($font,'-ascent')
    + $widget->fontMetrics($font,'-descent')
      + $num_newlines * $widget->fontMetrics($font,'-linespace');
}

sub widget_font_string_size {
  my ($widget,$font,$str) = @_;
  return ($widget->fontMeasure($font,$str),
          widget_font_string_height($widget,$font,$str));
}

# Round $n up to the next higher unit of the form 10^k, 2*10^k or 5*10^k
# (for an integer k, possibly negative) and return two values "($unit,
# $decimals)", where $decimals is how many decimal places are necessary to
# represent that unit.  For instance,
#
#     round_up_2_5_pow_10(0.0099) = (0.01, 2)
#     round_up_2_5_pow_10(0.15)   = (0.2, 1)
#     round_up_2_5_pow_10(3.5)    = (5, 0)
#     round_up_2_5_pow_10(60)     = (100, 0)
#
sub round_up_2_5_pow_10 {
  my ($n) = @_;
  my $k = ceil (POSIX::log10 ($n));
  my $unit = POSIX::pow (10, $k);

  # at this point $unit is the next higher value of the form 10^k, see if
  # either 5*10^(k-1) or 2*10^(k-1) would suffice to be bigger than $n
  if ($unit * 0.2 >= $n) {
    $unit *= 0.2;
    $k--;
  } elsif ($unit * 0.5 >= $n) {
    $unit *= 0.5;
    $k--;
  }
  ### $unit
  ### $k
  ### decimals: max (-$k, 0)
  return ($unit, max (-$k, 0));
}

# Return the number of digits in the integer part of $n, so for instance
#     _num_integer_digits(0) == 1
#     _num_integer_digits(99) == 2
#     _num_integer_digits(100.25) == 3
# Just the absolute value is used, so the results are the same for negatives,
#     num_integer_digits(-100.25) == 3
#
sub _num_integer_digits {
  my ($n) = @_;
  return 1 + max (0, floor (POSIX::log10 (abs ($n))));
}

1;
__END__
