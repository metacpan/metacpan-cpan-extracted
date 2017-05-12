# Copyright 2012, 2013 Kevin Ryde

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


# /z/so/x11r6.4/xc/programs/xterm/Tekproc.c
# /usr/share/doc/xterm/ctlseqs.txt.gz


package App::MathImage::Image::Base::Tektronix;
use 5.004;
use strict;
use Carp;
use POSIX 'floor';

use vars '$VERSION', '@ISA';
$VERSION = 110;

use Image::Base;
@ISA = ('Image::Base');

# uncomment this to run the ### lines
#use Smart::Comments '###';


use constant 1.02 _WIDTH => 4096;
use constant 1.02 _HEIGHT => 3072;

sub new {
  my ($class, %params) = @_;

  $params{'-addressing_bits'} ||= 12;
  if (ref $class) {
    my $self = $class;
    $class = ref $self;
    # if ($self->{'-filehandle'}) {
    #   croak "Cannot clone Tektronix after drawing begun";
    # }
    %params = (%$self, %params);  # inherit
    ### copy params: \%params
  } else {
    $params{'-colour'} ||= 'black';
  }
  $params{'-width'} = _WIDTH;
  $params{'-height'} = _HEIGHT;
  if (defined $params{'-file'}) {
    croak "Cannot load initial -file, Image::Base::Tektronix is output-only";
  }
  ### %params
  return bless \%params, $class;
}

sub DESTROY {
  my ($self) = @_;
  if ($self->{'-filehandle'}) {
    $self->save;
  }
}

sub set {
  my ($self, %param) = @_;
  ### Image-Base-Tektronix set(): \%param
  if (exists $param{'-height'}) {
    undef $self->{'-prev_x'};
    undef $self->{'-prev_y'};
  }
  %$self = (%$self, %param);
}

sub _get {
  my ($self, $key) = @_;
  if ($key eq '-width')  { return _WIDTH; }
  if ($key eq '-height') { return _HEIGHT; }
  return $self->SUPER::_get ($key);
}

sub save {
  my ($self, $filename) = @_;
  if (@_ > 1) {
    $self->set('-file', $filename);
  } else {
    $filename = $self->get('-file');
  }
  # print "\e\003"; # xterm vt100 mode
}

# not yet documented ...
sub save_fh {
  my ($self, $fh) = @_;
}

my %colour_is_black = (' ' => 1,
                       '0' => 1,
                       '#000' => 1,
                       '#000000' => 1,
                       '#000000000' => 1,
                       '#000000000000' => 1,
                       'clear' => 1,
                       'black' => 1);
sub xy {
  my ($self, $x,$y, $colour) = @_;
  ### Image-Base-Tektronix xy(): "$x,$y"

  if (@_ < 4) {
    croak "Cannot read back pixels from Tektronix";
  }
  if ($x < 0 || $x >= $self->{'-width'} || $y < 0 || $y >= $self->{'-height'}) {
    ### outside window ...
    return;
  }
  if ($colour_is_black{lc($colour)}) {
    ### skip black ...
    return;
  }

  if (! defined $self->{'-prev_x'} || $x != $self->{'-prev_x'}
      || ! defined $self->{'-prev_y'} || $y != $self->{'-prev_y'}) {
    print "\035", _packxy($self,$x,$y), _packxy($self,$x,$y);
  }
}

sub line {
  my ($self, $x1,$y1, $x2,$y2, $colour) = @_;
  ### Image-Base-Tektronix line(): "$x1,$y1, $x2,$y2  $colour"

  if ($colour_is_black{lc($colour)}) {
    ### skip black ...
    return;
  }
  ($x1,$y1, $x2,$y2) = _line_clipper ($x1,$y1, $x2,$y2, $self->{'-width'},$self->{'-height'})
    or do {
      ### line clipper all outside ...
      return;
    };

  ### line() clipped to: "x1=$x1,y1=$y1,  x2=$x2,y2=$y2   $colour"
  ### prev_x: $self->{'-prev_x'}
  ### prev_y: $self->{'-prev_y'}
  ### want move: (! defined $self->{'-prev_x'} || $x1 != $self->{'-prev_x'} || ! defined $self->{'-prev_y'} || $y1 != $self->{'-prev_y'})

  print(
        # move to x1,y1 if not already there
        (! defined $self->{'-prev_x'} || $self->{'-prev_x'} != $x1
         || ! defined $self->{'-prev_y'} || $self->{'-prev_y'} != $y1
         ? ("\035",
            _packxy($self,$x1,$y1))
         : ()),

        # draw to x2,y2
        _packxy($self,$x2,$y2));

  ### prev_x: $self->{'-prev_x'}
  ### prev_y: $self->{'-prev_y'}
}

# sub rectangle {
#   my $self = shift;
#   ### rectangle(): join(',',@_)
#   $self->SUPER::rectangle(@_);
# }

sub _packxy {
  my ($self,$x,$y) = @_;
  my $prev_x = $self->{'-prev_x'};
  my $prev_y = $self->{'-prev_y'};
  $self->{'-prev_x'} = $x;
  $self->{'-prev_y'} = $y;

  $y = $self->{'-height'}-1 - $y;
  if (defined $prev_y) {
    $prev_y = $self->{'-height'}-1 - $prev_y;
  }

  if ($self->{'-addressing_bits'} == 10) {
    $x <<= 2;
    $y <<= 2;
  }

  my $extra_changed = (! defined $prev_x || ($prev_x ^ $x) & 0x003
                       || ! defined $prev_y || ($prev_y ^ $y) & 0x003);
  my $high_x_changed = (! defined $prev_x || ($prev_x ^ $x) & 0xF80);

  return (
          # High Y if changed
          (! defined $prev_y || ($prev_y ^ $y) & 0xF80
           ? (chr(0x20 | (($y >> 7) & 0x1F)))     # 0x20 to 0x3F
           : ()),

          # Extra XY if changed
          ($extra_changed
           ? chr(0x60 | ($x & 0x03) | (($y << 2) & 0x0C))  # 0x60 to 0x6F
           : ()),

          # Low Y if changed, or if Extra or High X are sent
          ($extra_changed
           || $high_x_changed
           || ! defined $prev_y || ($prev_y ^ $y) & 0x7C
           ? chr(0x60 | (($y >> 2) & 0x1F))       # 0x60 to 0x3F
           : ()),

          # High X if changed
          ($high_x_changed
           ? chr(0x20 | (($x >> 7) & 0x1F))       # 0x20 to 0x3F
           : ()),

          # Low X always
          chr(0x40 | (($x >> 2) & 0x1F)));        # 0x40 to 0x3F
}

sub _line_clipper {
  my ($x1,$y1, $x2,$y2, $width, $height) = @_;

  return if ($x1 < 0 && $x2 < 0)
    || ($x1 >= $width && $x2 >= $width)
      || ($y1 < 0 && $y2 < 0)
        || ($y1 >= $height && $y2 >= $height);

  my $x1new = $x1;
  my $y1new = $y1;
  my $x2new = $x2;
  my $y2new = $y2;
  my $xlen = ($x1 - $x2);
  my $ylen = ($y1 - $y2);

  if ($x1new < 0) {
    $x1new = 0;
    $y1new = floor (0.5 + ($y1 * (-$x2)
                           + $y2 * ($x1)) / $xlen);
    ### x1 neg: "y1new to $x1new,$y1new"
  } elsif ($x1new >= $width) {
    $x1new = $width-1;
    $y1new = floor (0.5 + ($y1 * ($x1new-$x2)
                           + $y2 * ($x1 - $x1new)) / $xlen);
    ### x1 big: "y1new to $x1new,$y1new"
  }
  if ($y1new < 0) {
    $y1new = 0;
    $x1new = floor (0.5 + ($x1 * (-$y2)
                           + $x2 * ($y1)) / $ylen);
    ### y1 neg: "x1new to $x1new,$y1new   left ".($y1new-$y2)." right ".($y1-$y1new)
    ### x1new to: $x1new
  } elsif ($y1new >= $height) {
    $y1new = $height-1;
    $x1new = floor (0.5 + ($x1 * ($y1new-$y2)
                           + $x2 * ($y1 - $y1new)) / $ylen);
    ### y1 big: "x1new to $x1new,$y1new   left ".($y1new-$y2)." right ".($y1-$y1new)
  }
  if ($x1new < 0 || $x1new >= $width) {
    ### x1new outside
    return;
  }

  if ($x2new < 0) {
    $x2new = 0;
    $y2new = floor (0.5 + ($y2 * ($x1)
                           + $y1 * (-$x2)) / $xlen);
    ### x2 neg: "y2new to $x2new,$y2new"
  } elsif ($x2new >= $width) {
    $x2new = $width-1;
    $y2new = floor (0.5 + ($y2 * ($x1-$x2new)
                           + $y1 * ($x2new-$x2)) / $xlen);
    ### x2 big: "y2new to $x2new,$y2new"
  }
  if ($y2new < 0) {
    $y2new = 0;
    $x2new = floor (0.5 + ($x2 * ($y1)
                           + $x1 * (-$y2)) / $ylen);
    ### y2 neg: "x2new to $x2new,$y2new"
  } elsif ($y2new >= $height) {
    $y2new = $height-1;
    $x2new = floor (0.5 + ($x2 * ($y1-$y2new)
                           + $x1 * ($y2new-$y2)) / $ylen);
    ### y2 big: "x2new $x2new,$y2new"
  }
  if ($x2new < 0 || $x2new >= $width) {
    ### x2new outside
    return;
  }

  return ($x1new,$y1new, $x2new,$y2new);
}

1;
__END__

=for stopwords Tektronix filename Ryde

=head1 NAME

App::MathImage::Image::Base::Tektronix -- image drawing to a Tektronix terminal

=head1 SYNOPSIS

 use App::MathImage::Image::Base::Tektronix;
 my $image = App::MathImage::Image::Base::Tektronix->new;
 $image->rectangle (0,0, 99,99, 'black');
 $image->xy (20,20, 'black');
 $image->line (50,50, 70,70, 'black');
 $image->line (50,50, 70,70, 'black');

=head1 CLASS HIERARCHY

C<App::MathImage::Image::Base::Tektronix> is a subclass of
C<Image::Base>.

    Image::Base
      App::MathImage::Image::Base::Tektronix

=head1 DESCRIPTION

C<App::MathImage::Image::Base::Tektronix> extends C<Image::Base> to emit a
Tektronix terminal escape sequences.

=head1 FUNCTIONS

=over 4

=item C<$image = App::MathImage::Image::Base::Tektronix-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.

=back

=head1 ATTRIBUTES

=over

=item C<-width> (integer)

=item C<-height> (integer)

The size of the terminal in its addressable units.  For 12-bit addressing
this is width=4096, height=3072.  The actual visible resolution may be less
than this, in particular in various emulators it's almost certainly less.

=back

=head1 SEE ALSO

L<Image::Base>

=cut
