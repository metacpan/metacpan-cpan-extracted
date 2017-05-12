# size_request() broken ...


# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 Kevin Ryde

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

package App::MathImage::Gtk1::Ex::Units;
use 5.004;
use strict;
use Carp;
use List::Util 'max';

use vars '$VERSION', '@ISA', '@EXPORT_OK', '%EXPORT_TAGS';
$VERSION = 110;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(em ex char_width digit_width line_height
                    width height
                    set_default_size_with_subsizes
                    size_request_with_subsizes);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# uncomment this to run the ### lines
#use Devel::Comments;


#------------------------------------------------------------------------------

sub _font {
  my ($target) = @_;
  if ($target->can('get_style')) {
    return $target->get_style->font;
  }
  if ($target->isa('Gtk::Gdk::Font')) {
    return $target;
  }
  croak "Unrecognised units target $target";
}


#------------------------------------------------------------------------------

sub em {
  my ($target) = @_;
  # logical rect to include inter-char spacing, so that "3 em" is roughly
  # the width needed for "MMM"
  _font($target)->char_width(ord('M'));
}
sub ex {
  my ($target) = @_;
  my ($lbearing,$rbearing,$width,$ascent,$descent)
    = _font($target)->text_extents('x',1);
  return $ascent+$descent;
}
sub line_height {
  my ($target) = @_;
  my $font = _font($target);
  return $font->ascent + $font->descent;
}
sub char_width {
  my ($target) = @_;
  return _font($target)->text_measure("ABCDEFGHIJKLMNOPQRSTUVabcdefghijklmnopqrstuv",2*26) / (2*26);
}
sub digit_width {
  my ($target) = @_;
  my $font = _font($target);
  return max(map {$font->text_width($_,1)} 0..9);
}

#------------------------------------------------------------------------------
# width

use constant 1.02; # 1.02 for leading underscore on constant names
use constant _pixel => 1;
use constant _MILLIMETRES_PER_INCH => 25.4;

sub _mm_width {
  my ($target) = @_;
  return Gtk::Gdk->screen_width / Gtk::Gdk->screen_width_mm;
}
sub _inch_width {
  my ($target) = @_;
  return _MILLIMETRES_PER_INCH * _mm_width($target);
}
sub _screen_width {
  my ($target) = @_;
  return Gtk::Gdk->screen_width;
}
my %width = (pixel   => \&_pixel,
             pixels  => \&_pixel,
             char    => \&char_width,
             chars   => \&char_width,
             em      => \&em,
             ems     => \&em,
             digit   => \&digit_width,
             digits  => \&digit_width,
             mm      => \&_mm_width,
             inch    => \&_inch_width,
             inches  => \&_inch_width,
             screen  => \&_screen_width,
             screens => \&_screen_width,
            );

#------------------------------------------------------------------------------
# height

sub _mm_height {
  my ($target) = @_;
  my $screen = _to_screen($target);
  return Gtk::Gdk->screen_height / Gtk::Gdk->screen_height_mm;
}
sub _inch_height {
  my ($target) = @_;
  return _MILLIMETRES_PER_INCH * _mm_height($target);
}
sub _screen_height {
  my ($target) = @_;
  return Gtk::Gdk->screen_height;
}

my %height = (pixel   => \&_pixel,
              pixels  => \&_pixel,
              ex      => \&ex,
              exes    => \&ex,
              line    => \&line_height,
              lines   => \&line_height,
              mm      => \&_mm_height,
              inch    => \&_inch_height,
              inches  => \&_inch_height,
              screen  => \&_screen_height,
              screens => \&_screen_height,
             );

#------------------------------------------------------------------------------
# shared

sub width {
  push @_, \%width, \%height;
  goto \&_units;
}
sub height {
  push @_, \%height, \%width;
  goto \&_units;
}
sub _units {
  my ($target, $str, $h, $other) = @_;
  ### _units str: $str

  # it's easy to forget the $target arg, so check
  @_ == 4 or croak 'Units width()/height() expects 2 arguments';

  my ($amount,$unit) = ($str =~ /(.*?)\s*([[:alpha:]_]+)$/s)
    or return $str;

  if (my $func = $h->{$unit}) {
    return $amount * &$func ($target);
  }
  croak "Unrecognised unit \"$unit\"";
}


#-----------------------------------------------------------------------------

sub set_default_size_with_subsizes {
  my $window = $_[0];
  ### set_default_size_with_subsizes: "$window"

  my $req = size_request_with_subsizes (@_);
  ### $req
  $window->set_default_size ($req->width, $req->height);
}

sub size_request_with_subsizes {
  my ($widget, @elems) = @_;
  ### size_request_with_subsizes: "$widget"

  # Each change is guarded as it's made, in case the action on a subsequent
  # $widget provokes an error, eg. if not a Gtk::Widget.  A guard object
  # for each widget is a little less code than say an array of saved
  # settings and a loop to undo them.

  require Scope::Guard;
  my @guard;

  foreach my $elem (@elems) {
    my ($subwidget, $width, $height) = @$elem;
    # my ($save_width, $save_height) = $subwidget->get_size_request;
    my ($save_width, $save_height) = (-1,-1);  # get_usize ?
    my $width_pixels = (defined $width
                        ? width($subwidget,$width)
                        : $save_width);
    my $height_pixels = (defined $height
                         ? height($subwidget,$height)
                         : $save_height);
    push @guard, Scope::Guard->new
      (sub {
         ### restore usize: $save_width, $save_height
         $subwidget->set_usize ($save_width, $save_height);
       });
    $subwidget->set_usize ($width_pixels, $height_pixels);
  }

  ### size_request ...
  my $req = $widget->allocation;
  return $widget->size_request($req);
}

1;
__END__
