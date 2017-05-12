# Copyright 2013 Kevin Ryde

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



# filename is given in the device create
# fig,ps,x11,gd



package Image::Base::G2;
use 5.006;
use strict;
use warnings;
use Carp;
use G2;

use vars '$VERSION', '@ISA';
$VERSION = 110;

use Image::Base 1.12; # version 1.12 for ellipse() $fill
@ISA = ('Image::Base');

# uncomment this to run the ### lines
use Smart::Comments '###';


sub new {
  my ($class, %params) = @_;
  ### Image-Base-G2 new(): %params

  # $obj->new(...) means make a copy, with some extra settings
  if (ref $class) {
    my $self = $class;
    $class = ref $self;
    if (! defined $params{'-g2'}) {
      $params{'-g2'} = G2::copyImage($self->get('-g2'));
    }
    # inherit everything else
    %params = (%$self, %params);
    ### copy params: \%params
  }

  my $self = bless { -quality_percent  => -1,
                     -zlib_compression => -1,
                   }, $class;
  if (! defined $params{'-g2'}) {
    if (defined (my $filename = delete $params{'-file'})) {
      $self->load ($filename);

    } else {
      ### create G2 ...
      my $width = $params{'-width'};
      my $height = $params{'-height'};
      $self->{'-g2'} = G2::Device->newX11($width, $height);
    }
  }
  $self->set (%params);
  ### new made: $self
  return $self;
}

my %attr_to_get_func = (
                       );
sub _get {
  my ($self, $key) = @_;
  ### Image-Base-G2 _get(): $key

  if (my $func = $attr_to_get_func{$key}) {
    return &$func($self->{'-g2'});
  }
  return $self->SUPER::_get ($key);
}

sub set {
  my ($self, %param) = @_;
  ### Image-Base-G2 set(): \%param

  if (exists $param{'-g2'}) {
    $self->{'-g2'} = delete $param{'-g2'};
  }

  %$self = (%$self, %param);
}

sub load {
  my ($self, $filename) = @_;
  croak "Cannot load files into G2 device";
}

sub save {
  my ($self, $filename) = @_;
  ### Image-Base-G2 save(): @_
  if (@_ == 2) {
    croak "Cannot change filename in G2 device";
  }

  $self->{'-g2'}->save;
}

#------------------------------------------------------------------------------

sub xy {
  my ($self, $x, $y, $colour) = @_;
  ### Image-Base-G2 xy(): $x,$y,$colour

  my $g2 = $self->{'-g2'};
  if (@_ == 4) {
    _set_colour($self,$colour)->plot($x,$y);
  } else {
    croak "Cannot fetch pixels from G2 device";
  }
}

sub line {
  my ($self, $x1, $y1, $x2, $y2, $colour) = @_;
  ### Image-Base-G2 line(): @_
  _set_colour($self,$colour)->line($x1, $y1, $x2, $y2);
}

sub rectangle {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Image-Base-G2 rectangle(): @_[1..$#_]
  my $method = ($fill ? 'filled_rectangle' : 'rectangle');
  _set_colour($self,$colour)->$method($x1, $y1, $x2, $y2);
}  

sub ellipse {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  my $method = ($fill ? 'filled_ellipse' : 'ellipse');
  _set_colour($self,$colour)->$method(($x1+$x2)/2, ($y1+$y2)/2, # centre
                                      ($x2-$x1)/2, ($y2-$y1)/2); # radii
}  
  
#------------------------------------------------------------------------------
# colours
  
sub _set_colour {
  my ($self,$colour) = @_;
  my $g2 = $self->{'-g2'};
  $g2->pen($self->colour_to_ink($colour));
  return $g2;
}

# not documented, yet ...
sub colour_to_ink {
  my ($self, $colour) = @_;
  if (exists $self->{'-palette'}->{$colour}) {
    return $self->{'-palette'}->{$colour};
  }

  # 1 to 4 digit hex, equally spaced from 00 -> 0.0 through FF -> 1.0, or
  # FFFF -> 1.0 etc.
  # Crib: [:xdigit:] matches some wide chars, but hex() as of perl 5.12.4
  # doesn't accept them, so only 0-9A-F
  if ($colour =~ /^#(([0-9A-F]{3}){1,4})$/i) {
    my $len = length($1)/3; # of each group, so 1,2,3 or 4
    my $divisor = hex('F' x $len);
    return $self->{'-g2'}->ink(map {hex($_)/$divisor}
                               substr ($colour, 1, $len),   # full size groups
                               substr ($colour, 1+$len, $len),
                               substr ($colour, -$len));
  }

  croak "Unknown colour: $colour";
}

1;
__END__
