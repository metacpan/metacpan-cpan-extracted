# -file_format to select codec


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


package Image::Base::ExactImage;
use 5.006;
use strict;
use warnings;
use Carp;
use ExactImage;

use vars '$VERSION', '@ISA';
$VERSION = 110;

use Image::Base 1.12; # version 1.12 for ellipse() $fill
@ISA = ('Image::Base');

# uncomment this to run the ### lines
#use Smart::Comments '###';


sub new {
  my ($class, %params) = @_;
  ### Image-Base-ExactImage new(): %params

  # $obj->new(...) means make a copy, with some extra settings
  if (ref $class) {
    my $self = $class;
    $class = ref $self;
    if (! defined $params{'-exactimage'}) {
      $params{'-exactimage'} = ExactImage::copyImage($self->get('-exactimage'));
    }
    # inherit everything else
    %params = (%$self, %params);
    ### copy params: \%params
  }

  my $self = bless { -quality_percent  => -1,
                     -zlib_compression => -1,
                   }, $class;
  if (! defined $params{'-exactimage'}) {
    if (defined (my $filename = delete $params{'-file'})) {
      $self->load ($filename);

    } else {
      my $width = delete $params{'-width'};
      my $height = delete $params{'-height'};
      require ExactImage;
      my $exact = $self->{'-exactimage'} = ExactImage::newImageWithTypeAndSize(3,8,$width, $height);
    }
  }
  $self->set (%params);
  ### new made: $self
  return $self;
}

my %attr_to_get_func = (-width      => \&ExactImage::imageWidth,
                        -height     => \&ExactImage::imageHeight,

                        # these not documented yet ...
                        -channels  => \&ExactImage::imageChannels,
                        -depth     => \&ExactImage::imageChannelDepth,
                       );
sub _get {
  my ($self, $key) = @_;
  ### Image-Base-ExactImage _get(): $key

  if (my $func = $attr_to_get_func{$key}) {
    return &$func($self->{'-exactimage'});
  }
  return $self->SUPER::_get ($key);
}

sub set {
  my ($self, %param) = @_;
  ### Image-Base-ExactImage set(): \%param

  # these not documented yet ...
  if (exists $param{'-exactimage'}) {
    $self->{'-exactimage'} = delete $param{'-exactimage'};
  }

  if (exists $param{'-width'} || exists $param{'-height'}) {
    my $exact = $self->{'-exactimage'};
    ExactImage::resizeImage($exact,
                            (exists $param{'-width'}
                             ? delete $param{'-width'}
                             : ExactImage::imageWidth($exact)),
                            (exists $param{'-height'}
                             ? delete $param{'-height'}
                             : ExactImage::imageHeight($exact)));
  }

  %$self = (%$self, %param);
}

sub load {
  my ($self, $filename) = @_;
  if (@_ == 1) {
    $filename = $self->{'-file'};
  } else {
    $self->set('-file', $filename);
  }

  if (! ExactImage::decodeImageFile ($self->{'-exactimage'},
                                     $filename)) {
    croak 'Cannot load file ',$filename;
  }
}

sub save {
  my ($self, $filename) = @_;
  ### Image-Base-ExactImage save(): @_
  if (@_ == 2) {
    $self->set('-file', $filename);
  } else {
    $filename = $self->{'-file'};
  }
  ### $filename

# ,
#                                      $self->{'-quality_percent'},
#                                      $self->{'-zlib_compression'}
  if (! ExactImage::encodeImageFile ($self->{'-exactimage'},
                                     $filename)) {
    croak 'Cannot save file ',$filename;
  }
}

#------------------------------------------------------------------------------

sub xy {
  my ($self, $x, $y, $colour) = @_;
  ### Image-Base-ExactImage xy(): $x,$y,$colour

  my $exact = $self->{'-exactimage'};
  if (@_ == 4) {
    if ($colour eq 'None') {
      ExactImage::set($exact, $x,$y, 0,0,0,0);
    } else {
      ExactImage::set($exact, $x,$y, $self->colour_to_drgb($colour), 1);
    }
  } else {
    my ($red,$green,$blue,$alpha) = ExactImage::get($exact, $x,$y);
    if ($alpha < 1) {
      return 'None';
    }
    return sprintf ('#%02X%02X%02X', $red*255, $blue*255, $green*255);
  }
}

sub line {
  my ($self, $x1, $y1, $x2, $y2, $colour) = @_;
  ### Image-Base-ExactImage line(): @_

  ExactImage::setLineWidth(.1);
  ExactImage::imageDrawLine(_set_foreground($self,$colour),
                            $x1, $y1, $x2, $y2);
}

sub rectangle {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Image-Base-ExactImage rectangle(): @_[1..$#_]

  ExactImage::imageDrawRectangle(_set_foreground($self,$colour),
                                 $x1, $y1, $x2, $y2);
}  
  
#------------------------------------------------------------------------------
# colours
  
sub _set_foreground {
  my ($self,$colour) = @_;
  my $exact = $self->{'-exactimage'};
  if ($colour eq 'None') {
    ExactImage::setForegroundColor(0,0,0,0);
  } else {
    ExactImage::setForegroundColor($self->colour_to_drgb($colour),
                                   1.0);
  }
  return $exact;
}

# not documented, yet ...
sub colour_to_drgb {
  my ($self, $colour) = @_;
  if (exists $self->{'-palette'}->{$colour}) {
    $colour = $self->{'-palette'}->{$colour};
  }
  if (ref $colour) {
    return @$colour;
  }
  
  # 1 to 4 digit hex, equally spaced from 00 -> 0.0 through FF -> 1.0, or
  # FFFF -> 1.0 etc.
  # Crib: [:xdigit:] matches some wide chars, but hex() as of perl 5.12.4
  # doesn't accept them, so only 0-9A-F
  if ($colour =~ /^#(([0-9A-F]{3}){1,4})$/i) {
    my $len = length($1)/3; # of each group, so 1,2,3 or 4
    my $divisor = hex('F' x $len);
    return (map {hex($_)/$divisor}
            substr ($colour, 1, $len),      # full size groups
            substr ($colour, 1+$len, $len),
            substr ($colour, -$len));
  }
  
  croak "Unknown colour: $colour";
}

1;
__END__

=for stopwords ExactImage gd libgd filename Ryde Zlib Zlib's truecolor RGBA PNG png JPEG jpeg XPM WBMP SVG svg GIF wmf libjpeg

=head1 NAME

Image::Base::ExactImage -- draw images with ExactImage

=head1 SYNOPSIS

 use Image::Base::ExactImage;
 my $image = Image::Base::ExactImage->new (-width => 100,
                                   -height => 100);
 $image->rectangle (0,0, 99,99, 'white');
 $image->xy (20,20, 'black');
 $image->line (50,50, 70,70, '#FF00FF');
 $image->line (50,50, 70,70, '#0000AAAA9999');
 $image->save ('/some/filename.png');

=head1 CLASS HIERARCHY

C<Image::Base::ExactImage> is a subclass of C<Image::Base>,

    Image::Base
      Image::Base::ExactImage

=head1 DESCRIPTION

C<Image::Base::ExactImage> extends C<Image::Base> to create or update image
files in various formats using the C<ExactImage> module and library.

Native ExactImage drawing has more features but this module is an easy way
to point C<Image::Base> style code at a ExactImage and is a good way to get
PNG and other formats out of C<Image::Base> code.

=head2 Colour Names

Colour names for drawing are

    "#RGB"           hex upper or lower case
    "#RRGGBB"
    "#RRRGGGBBB"
    "#RRRRGGGGBBBB"
    "None"           transparent

Special "None" means transparent.  ExactImage works in a specified bit depth
so 3 and 4-digit hex forms may be truncated to the high digits.

=head2 File Formats

C<ExactImage> can read and write

    png      with libpng
    jpeg     with libjpeg
    gif      with libungif
    tiff     with libtiff
    xpm

C<load()> auto-detects the file format.

=head1 FUNCTIONS

See L<Image::Base/FUNCTIONS> for the behaviour common to all Image-Base
classes.

=over 4

=item C<$image = Image::Base::ExactImage-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  A new image can be started with
C<-width> and C<-height>,

    $image = Image::Base::ExactImage->new (-width => 200, -height => 100);

Or an existing file can be read,

    $image = Image::Base::ExactImage->new (-file => '/some/filename.png');

Or a C<ExactImage::Image> object can be given,

    $image = Image::Base::ExactImage->new (-exactimage => $exactimage);

=item C<$new_image = $image-E<gt>new (key=E<gt>value,...)>

Create and return a copy of C<$image>.  The ExactImage within C<$image> is
cloned (per C<$exact-E<gt>clone()>).  The optional parameters are applied to
the new image as per C<set()>.

    # copy image, new compression level
    my $new_image = $image->new (-zlib_compression => 9);

=item C<$colour = $image-E<gt>xy ($x, $y)>

=item C<$image-E<gt>xy ($x, $y, $colour)>

Get or set an individual pixel.

Currently the C<$colour> return is hex "#RRGGBB", or "None" for a fully
transparent pixel.  Partly transparent pixels are returned as a colour.

=item C<$image-E<gt>rectangle ($x1,$y1, $x2,$y2, $colour, $fill)>

Draw a rectangle with corners at C<$x1>,C<$y1> and C<$x2>,C<$y2>.  If
C<$fill> is true then it's filled, otherwise just the outline.

=item C<< $image->load >>

=item C<< $image->load ($filename) >>

Read the C<-file>, or set C<-file> to C<$filename> and then read.

=item C<$image-E<gt>save>

=item C<$image-E<gt>save ($filename)>

Save to C<-file>, or with a C<$filename> argument set C<-file> then save to
that.  The file format written is taken from the C<-file_format> (see
below).

=back

=head1 ATTRIBUTES

=over

=item C<-width> (integer)

=item C<-height> (integer)

...

=item C<-file_format> (string)

The file format as a string like "png" or "jpeg".  See L</File Formats>
above for the choices.

After C<load()> the C<-file_format> is the format read.  Setting
C<-file_format> can change the format for a subsequent C<save>.

The default is "png", which means a newly created image (not read from a
file) is saved as PNG by default.

=item C<-quality_percent> (0 to 100 or C<undef>)

The image quality when saving to JPEG format.  JPEG compresses by reducing
colours and resolution.  100 means full quality, no such reductions.
C<undef> means the libjpeg default (which is normally 75).

This becomes the quality parameter to C<encodeImage()>.

=item C<-zlib_compression> (integer 0-9 or -1, default -1)

The amount of data compression to apply when saving.  The value is Zlib
style 0 for no compression up to 9 for maximum effort.  -1 means Zlib's
default level (usually 6).

This becomes the compression level parameter to C<encodeImage()>.

=item C<-exactimage>

The underlying C<ExactImage::Image> object.

=back

=head1 SEE ALSO

L<Image::Base>,
L<ExactImage>

L<Image::Base::Magick>

=cut
