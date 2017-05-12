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


# file:///usr/share/doc/libcaca-dev/html/group__caca__primitives.html

# Term::Caca::Bitmap  for dithering only?
# Term::Caca::Sprite  load only?
#
# rectangle with given char, ascii chars, ibm line draw 


package App::MathImage::Image::Base::Caca;
use 5.006;  # Term::Caca might be 5.006
use strict;
use warnings;
use Carp;
use Term::Caca;
use vars '$VERSION', '@ISA';

use Image::Base;
@ISA = ('Image::Base');

$VERSION = 110;

# uncomment this to run the ### lines
#use Smart::Comments '###';

sub new {
  my ($class, %params) = @_;
  ### Image-Base-Caca new(): %params

  if (ref $class) {
    # $obj->new(...) means make a copy, with some extra settings
    croak "Cannot clone Image::Base::Caca";
    # my $self = $class;
    # if (! defined $params{'-caca'}) {
    #   $params{'-caca'} = $self->get('-caca')->Clone;
    # }
    # # inherit everything else
    # %params = (%$self, %params);
    # ### copy params: \%params
  }

  my $width  = delete $params{'-width'};
  my $height = delete $params{'-height'};
  if (! defined $params{'-caca'}) {
    my $caca = $params{'-caca'} = Term::Caca->new ($width, $height);
  }

  my $self = bless {}, $class;
  $self->set (%params);

  if (defined $self->{'filename'}) {
    $self->load;
  }

  ### new made: $self
  return $self;
}

my %attr_to_get = (-width      => 'get_width',
                   -height     => 'get_height');
sub _get {
  my ($self, $key) = @_;
  ### Image-Base-Caca _get(): $key

  if (my $method = $attr_to_get{$key}) {
    ### $method
    ### is: $self->{'-caca'}->$method
    return  $self->{'-caca'}->$method;
  }
  return $self->SUPER::_get ($key);
}

sub set {
  my ($self, %param) = @_;
  ### Image-Base-Caca set(): \%param

  foreach my $key ('-width', '-height') {
    if (exists $param{$key}) {
      croak "Attribute $key is read-only";
    }
  }

  # apply this first
  if (my $caca = delete $param{'-caca'}) {
    $self->{'-caca'} = $caca;
  }

  my $caca = $self->{'-caca'};
  # if (exists $param{'-width'} || exists $param{'-height'}) {
  #   my $width = (exists $param{'-width'} ? $param{'-width'} : $caca->get_width);
  #   my $height = (exists $param{'-height'} ? $param{'-height'} : $caca->get_height);
  #   $caca->set_size ($width, $height);
  # }

  # my @set;
  # while (my ($key, $value) = each %param) {
  #   if (my $method = $attr_to_set{$key}) {
  #     ### $method
  #     ### is: $self->{'-caca'}->$method($
  #     return  $caca->$method ($param{$key});
  #   }
  # }

  %$self = (%$self, %param);
}

sub load {
  my ($self, $filename) = @_;
  if (@_ == 1) {
    $filename = $self->get('-file');
  } else {
    $self->set('-file', $filename);
  }
  $self->{'-caca'}->import_from_file ($filename, $self->{'-file_format'});
}

sub save {
  my ($self, $filename) = @_;
  ### Image-Base-Caca save(): @_
  if (@_ == 2) {
    $self->set('-file', $filename);
  } else {
    $filename = $self->get('-file');
  }
  ### $filename
  open my $fh, "> $filename"
    or croak "Cannot open $filename: $!";
  print $fh $self->{'-caca'}->export_to_memory ($self->{'-file_format'})
    or croak "Error writing $filename: $!";
  close $fh
    or croak "Error closing $filename: $!";
}

sub xy {
  my ($self, $x, $y, $colour) = @_;
  #### Image-Base-Caca xy: $x,$y,$colour
  my $caca = $self->{'-caca'};
  if (@_ == 4) {
    $self->{'-caca'}->putchar ($x,$y, $colour);
  } else {
    return $caca->get_char ($x, $y);
  }
}
sub line {
  my ($self, $x1, $y1, $x2, $y2, $colour) = @_;
  ### Image-Base-Caca line: @_
  $self->{'-caca'}->draw_line ($x1,$y1, $x2,$y2, $colour);
}
sub rectangle {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Image-Base-Caca rectangle: @_

  my $method = ($fill ? 'fill_box' : 'box');
  $self->{'-caca'}->$method ($x1,$y1, $x2,$y2, $colour);
}
sub ellipse {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Image-Caca ellipse: "$x1, $y1, $x2, $y2, $colour"

  if ((($x1 - $x2) & 1) || (($y1 - $y2) & 1)) {
    # even width or height
    shift->SUPER::ellipse(@_);
  } else {
    # odd width and height
    my $method = ($fill ? 'fill_ellipse' : 'draw_ellipse');
    $self->{'-caca'}->$method (($x1+$x2)/2, ($y1+$y2)/2,       # centre
                               abs($x1-$x2)/2, abs($y1-$y2)/2, # a,b
                               $colour);
  }
}

# sub add_colours {
#   my $self = shift;
#   ### add_colours: @_
# 
#   # my $caca = $self->{'-caca'};
# }

1;
__END__

=for stopwords PNG Caca filename undef Ryde

=head1 NAME

App::MathImage::Image::Base::Caca -- draw images using Term::Caca

=head1 SYNOPSIS

 use App::MathImage::Image::Base::Caca;
 my $image = App::MathImage::Image::Base::Caca->new (-width => 100,
                                                     -height => 100);
 $image->rectangle (0,0, 99,99, 'white');
 $image->xy (20,20, 'black');
 $image->line (50,50, 70,70, '#FF00FF');
 $image->line (50,50, 70,70, '#0000AAAA9999');
 $image->save ('/some/filename.png');

=head1 CLASS HIERARCHY

C<App::MathImage::Image::Base::Caca> is a subclass of C<Image::Base>,

    Image::Base
      App::MathImage::Image::Base::Caca

=head1 DESCRIPTION

C<App::MathImage::Image::Base::Caca> extends C<Image::Base> to draw into
C<Term::Caca> canvases.

=head1 FUNCTIONS

=over 4

=item C<$image = App::MathImage::Image::Base::Caca-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  A new image can be started with
C<-width> and C<-height>,

    $image = App::MathImage::Image::Base::Caca->new (-width => 200, -height => 100);

Or an existing file can be read,

    $image = App::MathImage::Image::Base::Caca->new (-file => '/some/filename.png');

Or a C<Term::Caca> object canvas can be given,

    $image = App::MathImage::Image::Base::Caca->new (-caca => $cacacanvas);

=back

=head1 ATTRIBUTES

=over

=item C<-width> (integer)

=item C<-height> (integer)

Setting these changes the size of the image.

=item C<-caca>

The underlying C<Term::Caca> object.

=back

=head1 SEE ALSO

L<Image::Base>,
L<Image::Base::GD>,
L<Image::Base::PNGwriter>,
L<Term::Caca>,
L<Image::Xbm>,
L<Image::Xpm>,
L<Image::Pbm>

=cut
