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

package App::MathImage::Curses::Drawing;
use 5.004;
use strict;
use Carp;
use POSIX ();
use Module::Util;
use Curses 'doupdate';
use Curses::UI::Common 'split_to_lines';
use Curses::UI::Widget;

use App::MathImage::Generator;

use vars '$VERSION';
$VERSION = 110;

# uncomment this to run the ### lines
#use Smart::Comments;

use vars '@ISA';
@ISA = ('Curses::UI::Widget', 'Curses::UI::Common');

sub new {
  my $class = shift;
  my $self = $class->SUPER::new (-gen_options => {},
                                 -width  => undef,
                                 -height => undef,
                                 @_);
  $self->layout;
  return $self;
}

sub layout {
  my ($self) = @_;
  ### Drawing layout(): "@_"
  $self->SUPER::layout;
  return $self;
}

sub change_gen {
  my ($self, $key, $value) = @_;
  ### change_gen: $key
  $self->{'-gen_options'}->{$key} = $value;

  ### intellidraw:  $self->{-intellidraw}
  ### hidden: $self->hidden
  ### in_topwindow: $self->in_topwindow

  # $self->intellidraw;
  $self->draw;
  doupdate();
}

sub draw {
  my ($self, $no_doupdate) = @_;
  ### Drawing draw()
  if ($self->hidden) {
    ### hidden
    return $self;
  }
  $self->SUPER::draw(1) or return $self;

  if ($Curses::UI::color_support) {
    my $co = $Curses::UI::color_object;
    my $pair = $co->get_color_pair ($self->{-fg},
                                    $self->{-bg});

    $self->{-canvasscr}->attron(COLOR_PAIR($pair));
  }

  my $width = $self->canvaswidth;
  my $height = $self->canvasheight;
  ### $width
  ### $height

  #   my $str = $width . 'x'. $height;
  #   $self->{-canvasscr}->addstr(10, 10, $str);

  my $gen_options = $self->{'-gen_options'};
  $gen_options->{'width'} = $width;
  $gen_options->{'height'} = $height;
  ### $gen_options

  require Image::Base::Text;
  Image::Base::Text->VERSION(8);
  my $image = Image::Base::Text->new
    (-width  => $width,
     -height => $height);
  {
    my $gen = App::MathImage::Generator->new (%$gen_options);
    ### $gen
    $gen->draw_Image ($image);
  }
  my $str = App::MathImage::Image::Base::Other::save_string($image);
  ### $str
  # my $str = $image->save_string;
  # ### $str

  my $win = $self->{'-canvasscr'};
  my $y = 1;
  foreach my $line (@{split_to_lines($str)}) {
    # ### line: "$y  $line"
    $win->addstr($y++, 0, $line);
  }
  $win->move (0,0);

  $self->{-canvasscr}->noutrefresh;
  doupdate() unless $no_doupdate;

  ### draw() done
  return $self;
}

1;
__END__
