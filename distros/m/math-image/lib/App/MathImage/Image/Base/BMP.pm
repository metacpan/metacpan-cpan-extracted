# setting -file dodgy ...
# must start from an open file ... ?



# Copyright 2011, 2012, 2013 Kevin Ryde

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


package App::MathImage::Image::Base::BMP;
use 5.004;
use strict;
use Carp;
use Image::BMP ();

use vars '$VERSION', '@ISA';
$VERSION = 110;

use Image::Base;
@ISA = ('Image::Base');

# uncomment this to run the ### lines
#use Devel::Comments '###';

sub new {
  my ($class, %params) = @_;
  ### Image-Base-BMP new(): %params

  # $obj->new(...) means make a copy, with some extra settings
  if (ref $class) {
    croak "Cannot clone";
  }

  if (! defined $params{'-imagebmp'}) {
    $params{'-imagebmp'} = Image::BMP->new (Width  => ($params{'-width'}||0),
                                            Height => ($params{'-height'}||0));
  }
  my $self = bless {}, $class;
  $self->set (%params);

  if (defined $params{'-file'}) {
    $self->load;
  }

  ### new made: $self
  return $self;
}


my %attr_to_get_field = (-width    => 'Width',
                         -height   => 'Height',
                         -file     => 'file',
                         -ncolours => 'ColorsUsed',
                        );
### %attr_to_get_field
sub _get {
  my ($self, $key) = @_;
  ### Image-Base-BMP _get(): $key

  if (my $field = $attr_to_get_field{$key}) {
    ### $field
    ### is: $self->{'-imagebmp'}->{$field}
    return  $self->{'-imagebmp'}->{$field}
  }
  return $self->SUPER::_get ($key);
}

sub set {
  my ($self, %param) = @_;
  ### Image-Base-BMP set(): \%param

  foreach my $key ('-ncolours') {
    if (exists $param{$key}) {
      croak "Attribute $key is read-only";
    }
  }

  # apply this first
  if (my $bmp = delete $param{'-imagebmp'}) {
    $self->{'-imagebmp'} = $bmp;
  }

  foreach my $key (keys %param) {
    ### $key
    ### value: $param{$key}
    ### field: $attr_to_get_field{$key}
    if (my $field = $attr_to_get_field{$key}) {
      $self->{'-imagebmp'}->{$field} = delete $param{$key};
    }
  }

  %$self = (%$self, %param);
}

sub load {
  my ($self, $filename) = @_;
  ### Image-Base-BMP load(): @_
  my $bmp = $self->{'-imagebmp'};
  if (@_ == 1) {
    ### load() existing ...
    $bmp->load;
  } else {
    ### load(): $filename
    $bmp->load($filename);
  }
}

sub save {
  my ($self, $filename) = @_;
  ### Image-Base-BMP save(): @_
  my $bmp = $self->{'-imagebmp'};
  if (@_ == 1) {
    $bmp->load;
  } else {
    $bmp->load($filename);
  }
}

sub xy {
  my ($self, $x, $y, $colour) = @_;
  ### Image-Base-BMP xy: $x,$y,$colour
  my $bmp = $self->{'-imagebmp'};
  if (@_ == 4) {
    if ($colour =~ /^#(([0-9A-F]{3}){1,4})$/i) {
      my $len = length($1)/3; # of each group, so 1,2,3 or 4
      $bmp->xy_rgb ($x,$y,
                    (map {hex(substr($_ x 2, 0, 2))}  # first 2 chars
                     substr ($colour, 1, $len),
                     substr ($colour, 1+$len, $len),
                     substr ($colour, -$len)));
    } else {
      croak "Unrecognised colour: $colour";
    }

  } else {
    return sprintf ('#%02X%02X%02X', $bmp->xy_rgb ($x, $y));
  }
}

# sub add_colours {
#   my $self = shift;
#   ### add_colours: @_
#   $self->{'-imagebmp'}->addcolors (colors => \@_);
# }


1;
__END__

=for stopwords BMP filename Ryde RGB Image-Base-BMP

=head1 NAME

App::MathImage::Image::Base::BMP -- draw BMP images using Image::BMP

=head1 SYNOPSIS

 use App::MathImage::Image::Base::BMP;
 my $image = App::MathImage::Image::Base::BMP->new (-width => 100,
                                                    -height => 100);
 $image->rectangle (0,0, 99,99, '#FFF'); # white
 $image->xy (20,20, '#000');             # black
 $image->line (50,50, 70,70, '#FF00FF');
 $image->line (50,50, 70,70, '#0000AAAA9999');
 $image->save ('/some/filename.bmp');

=head1 CLASS HIERARCHY

C<App::MathImage::Image::Base::BMP> is a subclass of C<Image::Base>,

    Image::Base
      App::MathImage::Image::Base::BMP

=head1 DESCRIPTION

C<App::MathImage::Image::Base::BMP> extends C<Image::Base> to create or
update image files using the C<Image::BMP> module.

=head2 Colour Names

There's no named colours as such, only hex

    #RGB
    #RRGGBB
    #RRRGGGBBB
    #RRRRGGGGBBBB

=head1 FUNCTIONS

=over 4

=item C<$image = App::MathImage::Image::Base::BMP-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  A new image can be started with
C<-width> and C<-height>,

    $image = App::MathImage::Image::Base::BMP->new (-width => 200, -height => 100);

Or an existing file can be read,

    $image = App::MathImage::Image::Base::BMP->new (-file => '/some/filename.bmp');

Or an C<Image::BMP> object can be given,

    my $bmpobj = Image::BMP->new (20, 10);
    $image = App::MathImage::Image::Base::BMP->new (-imagebmp => $bmpobj);

=item C<$new_image = $image-E<gt>new (key=E<gt>value,...)>

There's no image clone as yet.

=item C<$image-E<gt>load ()>

=item C<$image-E<gt>load ($filename)>

Read the C<-file>, or set C<-file> to C<$filename> and then read.

=item C<$image-E<gt>save ()>

=item C<$image-E<gt>save ($filename)>

Save to C<-file>, or with a C<$filename> argument set C<-file> then save to
that.

=back

=head1 ATTRIBUTES

=over

=item C<-width> (integer)

=item C<-height> (integer)

The size of the image.

=item C<-imagebmp>

The underlying C<Image::BMP> object.

=back

=head1 SEE ALSO

L<Image::Base>,
L<Image::BMP>

=cut
