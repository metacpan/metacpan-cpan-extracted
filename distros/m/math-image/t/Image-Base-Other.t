#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-Image is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Math-Image.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;
plan tests => 1;

use App::MathImage::Image::Base::Other;

# uncomment this to run the ### lines
#use Smart::Comments;

# whether to mark repeat-drawn pixels as "X" (repeat drawn pixels being
# wasteful and undesirable if they can be avoided reasonably easily).
my $MyGrid_flag_overlap = 1;

ok(1,1);

{
  package MyGrid;
  use Image::Base;
  use vars '@ISA';
  @ISA = ('Image::Base');
  sub new {
    my $class = shift;
    my $self = bless { @_}, $class;
    my $horiz = '+' . ('-' x $self->{'-width'}) . "+\n";
    $self->{'str'} = $horiz
      . (('|' . (' ' x $self->{'-width'}) . "|\n") x $self->{'-height'})
        . $horiz;
    return $self;
  }
  sub xy {
    my ($self, $x, $y, $colour) = @_;
    die "x=$x,y=$y negative" if $x < 0 || $y < 0;
    die if $x >= $self->{'-width'};
    die if $y >= $self->{'-height'};
    my $pos = $x+1 + ($y+1)*($self->{'-width'}+3);
    if (@_ < 4) {
      return substr ($self->{'str'}, $pos, 1);
    }

    if ($MyGrid_flag_overlap) {
      if (substr ($self->{'str'}, $pos, 1) ne ' ') {
        # doubled up pixel, undesirable, treated as an error
        $colour = 'X';
      }
    }
    substr ($self->{'str'}, $pos, 1) = $colour;
  }
}


#------------------------------------------------------------------------------
# diamond() cf line()

sub fill {
  my ($image) = @_;
  my $w = $image->get('-width');
  foreach my $y (0 .. $image->get('-height')-1) {
    ### fill: $y
    my ($x1, $x2, $colour);
    for ($x1 = 0; $x1 < $w; $x1++) {
      $colour = $image->xy($x1,$y);
      if ($colour ne ' ') {
        last;
      }
    }
    ### $colour
    next if $colour eq ' ';
    for ($x2 = $w-1; $x2 >= 0; $x2--) {
      if ($image->xy($x2,$y) ne ' ') {
        last;
      }
    }
    $image->line($x1,$y, $x2,$y, $colour);
  }
}

# {
#   $MyGrid_flag_overlap = 0;
# 
#   my $x1 = 1;
#   my $y1 = 1;
#   foreach my $w (1 .. 20) {
#     foreach my $h (1 .. 20) {
#       my $x2 = $x1+$w-1;
#       my $y2 = $y1+$h-1;
# 
#       foreach my $fill (0, 1) {
#         my $iline = MyGrid->new (-width => $w+2, -height => $h+2);
#         my $idiamond = MyGrid->new (-width => $w+2, -height => $h+2);
# 
#         my $xcl = $x1 + int (($x2-$x1)/2);
#         my $xch = $x1 + int (($x2-$x1+1)/2);
#         my $ycl = $y1 + int (($y2-$y1)/2);
#         my $ych = $y1 + int (($y2-$y1+1)/2);
#         ### $xcl
#         ### $xch
#         ### $ycl
#         ### $ych
#         $iline->line ($xcl,$y1, $x1,$ycl, '*');
#         $iline->line ($xch,$y1, $x2,$ycl, '*');
#         $iline->line ($xcl,$y2, $x1,$ych, '*');
#         $iline->line ($xch,$y2, $x2,$ych, '*');
#         ### line: "$xcl,1, 1,$ycl"
#         ### line: "$xch,1, $x2,$ycl"
#         ### line: "$xcl,$y2, $ych,$ych"
#         ### line: "$xch,$y2, $ych,$ych"
#         if ($fill) {
#           fill ($iline);
#         }
# 
#         App::MathImage::Image::Base::Other::diamond
#             ($idiamond, $x1,$y1, $x2,$y2, '*', $fill);
#         my $line_str = $iline->{'str'};
#         my $diamond_str = $idiamond->{'str'};
#         is ("\n".$diamond_str,
#             "\n".$line_str,
#             "diamond vs line $x1,$y1, $x2,$y2  w=$w,h=$h fill=$fill");
#       }
#     }
#   }
# }

exit 0;
