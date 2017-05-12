package Wx::Perl::Imagick;
use strict;
use warnings;

our $VERSION = '0.02';

use Wx qw(wxNullBitmap);
use Image::Magick;
use IO::Scalar;
use Wx::Perl::Carp qw(cluck);
use base 'Clone';
#----------------------------------------------------------------------
# Compatibility methods for Wx::Image
#
sub new
{
    my $proto    = shift;
    my $class    = ref($proto) || $proto;
    my $self     = {};
    $self->{_im} = Image::Magick->new();
    
    # When we convert the Wx::Perl::Imagick object to a Wx::Bitmap we convert
    # it to PNG first...so we need the PNGHandler
    Wx::Image::AddHandler(Wx::PNGHandler->new);
    
    bless $self, $class;
    
    if (UNIVERSAL::isa($_[0], 'Wx::Bitmap'))
    {
        my $bitmap = shift;
        my $img = $bitmap->ConvertToImage;
        if (defined $img)
        {
            $self->{_index}  = 0;
            $self->MagickError($self->Set(size => $img->GetWidth."x".$img->GetHeight));
            $self->MagickError($self->SetData($img->GetData));
            return undef unless $self->GetLoadedImageCount;
        }
        else
        {
            print STDERR "Could not convert this Wx::Bitmap to Wx::Perl::Imagick";
            return undef;
        }

    }
    elsif (UNIVERSAL::isa($_[0], 'Wx::Icon'))
    {
        my $img = Wx::Bitmap->new(shift)->ConvertToImage;
        if (defined $img)
        {
            $self->{_index}  = 0;
            $self->MagickError($self->Set(size => $img->GetWidth."x".$img->GetHeight));
            $self->MagickError($self->SetData($img->GetData));
            return undef unless $self->GetLoadedImageCount;
        }
        else
        {
            print STDERR "Could not convert this Wx::Icon to Wx::Perl::Imagick";
            return undef;
        }
    }
    elsif (($_[0] =~ /^\d+$/) && ($_[1] =~ /^\d+$/))
    {
        $self->{_width}  = shift;
        $self->{_height} = shift;
        $self->{_data}   = shift;
        $self->{_index}  = 0;
        $self->MagickError($self->Set(size => "$self->{_width}x$self->{_height}"));
        if ($self->{_data})
        {
            $self->MagickError($self->SetData($self->{_data}));
            $self->Set(magick => 'PNG');
            return undef unless $self->GetLoadedImageCount;
        }
    }
    else
    {
        $self->{_file} = shift;
        if (defined $_[0])
        {
            print STDERR "The supplied type or mimetype is ignored";
            shift;
        }
        $self->{_index} = shift || 0;
        if ($self->{_index} == -1)
        {
            $self->{_index} = 0;
        }
        $self->MagickError($self->Read($self->{_file}));
        return undef unless $self->GetLoadedImageCount;
    }
    
    return $self;
}

sub SetData
{
    my $self = shift;
    my $data = shift;
    my $oldmagick    =  $self->Get('magick');
    $self->MagickError( $self->Set(magick => 'RGB')      );
    $self->MagickError( $self->BlobToImage(pack("C*",  map{ord($_)} split //, $data))        );
    $self->MagickError( $self->Set(magick => $oldmagick) ) if $oldmagick;
}

sub GetData
{
    my $self = shift;
    my $oldmagick    =  $self->Get('magick') || 'PNG';
    $self->MagickError( $self->Set(magick => 'RGB')      );
    my $data; 
    $data = unpack "C*", $self->ImageToBlob();
    $self->MagickError( $self->Set(magick => $oldmagick) ) if $oldmagick;
    return $data;
}

sub ConvertToBitmap
{
    my $self = shift;
    my $bmp;
    if (my $imgs = $self->GetLoadedImageCount)
    {
        my $oldmagick    =  $self->Get('magick');
        # Convert the image to some format that Wx::Image can handle...I just chose PNG
        # because it also ensures preservation of transparency
        $self->MagickError( $self->Set(magick => 'PNG')      );
        my $data;
        $data = $self->ImageToBlob();
        $bmp = Wx::Bitmap->new(Wx::Image->newStreamMIME(IO::Scalar->new(\$data), $self->Get('mime')));
        $self->MagickError( $self->Set(magick => $oldmagick) ) if $oldmagick;
    }
    else
    {
        $bmp = wxNullBitmap;
    }
    return $bmp;
}

sub AddHandler
{
    print STDERR "Wx::Perl::Imagick doesn't use wxWidget's imagehandlers";
}

sub CleanupHandlers
{
    print STDERR "Wx::Perl::Imagick doesn't use wxWidget's imagehandlers";
}

sub ComputeHistogram
{
    $_[0]->Histogram;
}

sub ConvertToMono
{
    my $self = shift;
    $self->Quantize(colorspace=>'gray',colors=>2,dither=>'false');
}

sub Copy
{
    return $_[0]->clone();
}

sub Destroy
{
    $_[0] = undef;
}

sub FindHandler
{
    print STDERR "Wx::Perl::Imagick doesn't use wxWidget's imagehandlers";
}

sub GetHandlers
{
    print STDERR "Wx::Perl::Imagick doesn't use wxWidget's imagehandlers";
}

sub GetBlue
{
    my $self = shift;
    my ($x, $y) = @_;
    my @pixel = split(/,/, $self->Get("pixel[$x,$y]"));
    return $pixel[2];
}

sub GetGreen
{
    my $self = shift;
    my ($x, $y) = @_;
    my @pixel = split(/,/, $self->Get("pixel[$x,$y]"));
    return $pixel[1];
}

sub GetRed
{
    my $self = shift;
    my ($x, $y) = @_;
    my @pixel = split(/,/, $self->Get("pixel[$x,$y]"));
    return $pixel[0];
}

sub GetMaskBlue
{
    my $self = shift;
    my $data = $self->ImageToBlob(magick => 'RGBA'); 
    my @rgba = split(//,$data); 
    while ( my ($r, $g, $b, $a) = splice(@rgba, 0, 4)) 
    {
        if (ord($a) == 0 )
        {
            return ord($b);
        }
    }
}

sub GetMaskGreen
{
    my $self = shift;
    my $data = $self->ImageToBlob(magick => 'RGBA'); 
    my @rgba = split(//,$data); 
    while ( my ($r, $g, $b, $a) = splice(@rgba, 0, 4)) 
    {
        if (ord($a) == 0 )
        {
            return ord($g);
        }
    }
}

sub GetMaskRed
{
    my $self = shift;
    my $data = $self->ImageToBlob(magick => 'RGBA'); 
    my @rgba = split(//,$data); 
    while ( my ($r, $g, $b, $a) = splice(@rgba, 0, 4)) 
    {
        if (ord($a) == 0 )
        {
            return ord($r);
        }
    }
}

sub GetHeight
{
    my $self = shift;
    return $self->Get('rows');
}

sub GetPalette
{
    print STDERR "Wx::Perl::Imagick::GetPalette is not implemented";
}

sub GetSubImage
{
    my $self = shift;
    my $rect = shift;
    my $x = $rect->x;
    my $y = $rect->y;
    my $width = $rect->width;
    my $height = $rect->height;
    my $clone = $self->clone;
    my $geo = $width."x".$height."+".$x."+".$y;
    $clone->Crop(geometry=>$geo);
    return $clone;
}

sub GetWidth
{
    my $self = shift;
    return $self->Get('columns');
}

sub HasMask
{
    my $self = shift;
    return $self->Get('matte');
}

sub GetOption
{
    my $self = shift;
    my $option = shift;
    return $self->Get($option);
}

sub GetOptionInt
{
    my $self = shift;
    my $option = shift;
    return $self->Get($option);
}

sub HasOption
{
    my $self = shift;
    my $option = shift;
    my $x = $self->Get($option);
    return defined $x;
}

sub InitStandardHandlers
{
    print STDERR "Wx::Perl::Imagick doesn't use wxWidget's imagehandlers";
}

sub InsertHandler
{
    print STDERR "Wx::Perl::Imagick doesn't use wxWidget's imagehandlers";
}

sub LoadFile
{
    my $self = shift;
    $self->Read(shift);
}

sub Ok
{
    my $self = shift;
    return 1 if $self->GetLoadedImageCount();
    return 0;
}

sub RemoveHandler
{
    print STDERR "Wx::Perl::Imagick doesn't use wxWidget's imagehandlers";
}

sub SaveFile
{
    my $self = shift;
    $self->Write(shift);
}

sub Mirror
{
    my $self = shift;
    my $horizontally = shift;
    $horizontally = 1 unless defined $horizontally;
    my $clone = $self->clone;
    $clone->Flop() if $horizontally;
    $clone->Flip() unless $horizontally;
    return $clone;
}

sub Replace
{
    print STDERR "Wx::Perl::Imagick::Replace has not yet been implemented";
}

sub Rescale
{
    my $self = shift;
    $self->Scale(@_)
}

sub Rotate90
{
    my $self = shift;
    my $clockwise = shift;
    $clockwise = 1 if not defined $clockwise;
    my $degrees = $clockwise ? 90 : -90;
    my $clone = $self->clone;
    MagickError($clone->Rotate(degrees => $degrees));
    return $clone;
}

sub SetMask
{
    my $self = shift;
    my $mask = shift;
    $mask = 1 unless defined $mask;
    $self->Set('matte' => $mask == 1 ? 'True' : 'False');
}

sub SetMaskColour
{
    my ($self, $r, $g, $b) = @_;
    $self->Transparent(color => sprintf('#%02x%02x%02x', $r,$g,$b));
}

sub SetMaskFromImage
{
    print STDERR "Wx::Perl::Imagick::SetMaskFromImage is not implemented";
}

sub SetOption
{
    my $self = shift;
    return $self->Set(@_);
}

sub SetPalette
{
    print STDERR "Wx::Perl::Imagick::SetPalette is not implemented";
}

sub SetRGB
{
    my ($self, $x, $y, $r, $g, $b) = @_;
    $self->Set("pixel[$x,$y]", sprintf('#%02x%02x%02x', $r,$g,$b));
}

#----------------------------------------------------------------------
# Compatibility methods for Image::Magick
#
our ($AUTOLOAD);
sub AUTOLOAD
{
    my $self = shift;
    my @params = @_;
    (my $auto = $AUTOLOAD) =~ s/.*:://;
    my $obj;
    if ((exists $self->{_im}->[$self->{_index}]) && ($auto ne 'Read'))
    {
        $obj = $self->{_im}->[$self->{_index}];
    }
    else
    {
        $obj = $self->{_im};
    }
    if ($obj->can($auto))
    {
        return $obj->$auto(@params);
    }
    else
    {
        print STDERR "Unknown method $auto called";
    }
}

#----------------------------------------------------------------------
# Convenience methods
#
sub MagickError
{
    my $self  = shift;
    my $error = shift;
    cluck "Image::Magick returned an error: \n$error" if $error;
}

sub SetIndex
{
    $_[0]->{_index} = $_[1];
}

sub GetIndex
{
    $_[0]->{_index};
}

sub GetLoadedImageCount
{
    return $#{$_[0]->{_im}}+1;
}


=head1 NAME

Wx::Perl::Imagick - A drop-in replacement for Wx::Image with all functionality of Image::Magick

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Wx::Perl::Imagick;

    # Load an imagefile that contains more than one image
    my $image = Wx::Perl::Imagick->new('pvoice.ico');
    my $bmp = Wx::StaticBitmap->new($panel, -1, $image->ConvertToBitmap);

    # Select the next image in the file
    $image->SetIndex(1);
    $bmp = Wx::StaticBitmap->new($panel, -1, $image->ConvertToBitmap, [100,100]);

    # We can also create an image from a Wx::Image
    my $img = Wx::Image->new('car.jpg','image/jpeg');
    my $magick = Wx::Perl::Imagick->new($img->GetWidth, $img->GetHeight, $img->GetData);
    my $bitmap = $magick->ConvertToBitmap;
    my $bmp2 = Wx::StaticBitmap->new($panel, -1, $bitmap, [300,300]) if $bitmap->Ok; 

    # Or we can create an image from a Wx::Bitmap
    my $frombmp = Wx::Perl::Imagick->new($bitmap);
    my $newbitmap = $newbitmap->ConvertToBitmap;
    $bmp = Wx::StaticBitmap->new($panel, -1, $newbitmap, [400,400]) if $newbitmap->Ok;

    # And we can create an image from a Wx::Icon
    my $icon = Wx::Icon->new('pvoice.ico',wxBITMAP_TYPE_ICO, 16,16 );
    my $fromicon = Wx::Perl::Imagick->new($icon);
    my $anotherbitmap = $fromicon->ConvertToBitmap;
    $bmp = Wx::StaticBitmap->new($panel, -1, $anotherbitmap, [500,500]) if $anotherbitmap->Ok;
    ...

    # Now it's also possible to use Image::Magick's conversions and filters
    $magick->->Crop(geometry=>'100x100"+100"+100');
    ...

=head1 DESCRIPTION

This class is meant to be a replacement for Wx::Image, adding all functionality of Image::Magick. Hence
the name Wx::Perl::Imagick.
Most of the API of Wx::Image has been copied for backwards compatibility, but you can also call any method
of Image::Magick on a constructed Wx::Perl::Magick instance. This will greatly improve the possibilities
you have with an image in wxPerl.

=head1 INCOMPATIBILITIES

While I've tried to keep all methodcalls that Wx::Image knows the same for Wx::Perl::Imagick, there are 
some incompatible differences. You can find these differences in the 'Wx::Image compatible METHODS' section below. 

=head1 Wx::Image compatible METHODS

=head2 new

There are several ways to construct a new Wx::Perl::Imagick object. These are:

=over 4

=item Wx::Perl::Imagick->new(bitmap)

Simply supply a Wx::Bitmap and it will create a Wx::Perl::Imagick object from it.

=item Wx::Perl::Imagick->new(icon)

Simply supply a Wx::Icon and it will create a Wx::Perl::Imagick object from it.

=item Wx::Perl::Imagick->new(width, height)

This will create a new, empty Wx::Perl::Imagick object with the given width and height.

=item Wx::Perl::Imagick->new(width, height, data)

This will create a new Wx::Perl::Imagick object from the supplied data (which can be -for example-
generated from Wx::Image's GetData), using the given width and height.

=item Wx::Perl::Imagick->new(file, (mime)type, index = 0)

This will load the file indicated. If a mimetype or type is supplied, the constructor will 
generate a print STDERRing, because Wx::Perl::Imagick lets Image::Magick figure out the type of the file, and
ignores this parameter. 
The index points out which of the images that the indicated file provides will be the default one.
To use this form without print STDERRings, you'd better call it like this:

    Wx::Perl::Imagick->new('somefile.jpg', undef, 0); # you can omit the last two parameters if you like

=item Wx::Perl::Imagick->new( stream, (mime)type, index ) 

This form IS NOT SUPPORTED. Therefore it's an incompatible difference between Wx::Image and Wx::Perl::Imagick.

=back

=head2 AddHandler

This method does nothing. Wx::Perl::Magick does not use wxWidget's ImageHandlers;

=head2 CleanupHandlers

This method does nothing. Wx::Perl::Magick does not use wxWidget's ImageHandlers;

=head2 ComputeHistogram

Unlike wxPerl, Wx::Perl::Imagick does implement it, albeit just an alias for Image::Magick's Histogram() method.
It returns the unique colors in the image and a count for each one. The returned values are an array of 
red, green, blue, opacity, and count values.

=head2 ConvertToBitmap

Unlike wxPerl, Wx::Perl::Imagick does implement this, because we need a way to convert between
Wx::Perl::Imagick objects and Wx::Bitmap objects. Since Wx::Bitmap does not know about Wx::Perl::Magick, 
we need to make Wx::Perl::Magick aware of a Wx::Bitmap...
It does just what it suggests, it returns a bitmap from the currently loaded image.

=head2 ConvertToMono

Returns monochromatic version of the image. The returned image has white colour where the original 
has (r,g,b) colour and black colour everywhere else.

=head2 Copy

Returns an identical copy of the image.

=head2 Create

Not implemented. Use new() instead.

=head2 Destroy

Destroys the image data

=head2 FindFirstUnusedColour

Not implemented in wxPerl, not here either

=head2 FindHandler

This method does nothing. Wx::Perl::Magick does not use wxWidget's ImageHandlers;

=head2 GetBlue(x, y)

Returns the blue intensity at the given coordinate.

=head2 GetData

Returns the image data as an array. This is most often used when doing direct image 
manipulation. The return value points to an array of characters in RGBRGBRGB... format.

=head2 GetGreen(x, y)

Returns the green intensity at the given coordinate.

=head2 GetImageCount

Not implemented. See GetLoadedImageCount below

=head2 GetHandlers

This method does nothing. Wx::Perl::Magick does not use wxWidget's ImageHandlers;

=head2 GetHeight

Gets the height of the image in pixels.

=head2 GetMaskBlue

Gets the blue value of the transparent colour. 

=head2 GetMaskGreen

Gets the green value of the transparent colour. 

=head2 GetMaskRed

Gets the red value of the transparent colour. 

=head2 GetPalette

Not implemented.

=head2 GetRed(x, y)

Returns the red intensity at the given coordinate.

=head2 GetSubImage(rect)

Returns a sub image of the current one as long as the rect (of type Wx::Rect) belongs entirely to the image.

=head2 GetWidth

Gets the width of the image in pixels

=head2 HasMask

Returns 1 if there is a mask active, 0 otherwise.

=head2 GetOption

This is implemented in a different manner than in Wx::Image. It is in fact an alias for Image::Magick's
Get() method. The suggested option 'quality' in the Wx::Image documentation works perfectly with GetOption('quality').
Since this method not documented any further in the wxWidgets documentation, I implemented it this way.

It can however return anything that Image::Magick returns (being a string or an integer)

=head2 GetOptionInt

See GetOption.

=head2 HasOption

=head2 InitStandardHandlers

This method does nothing. Wx::Perl::Magick does not use wxWidget's ImageHandlers;

=head2 InsertHandler

This method does nothing. Wx::Perl::Magick does not use wxWidget's ImageHandlers;

=head2 LoadFile(filename)

This loads the file indicated by filename. The second parameter that Wx::Image specifies is ignored (the filetype),
since Image::Magick doesn't need any specification of the filetype.

=head2 Ok

This returns 1 if an image has been loaded. Returns 0 otherwise.

=head2 RemoveHandler

This method does nothing. Wx::Perl::Magick does not use wxWidget's ImageHandlers;

=head2 SaveFile

This saves the image to a file named filename. The second parameter that Wx::Image specifies is ignored (the filetype),
since Image::Magick doesn't need any specification of the filetype.

=head2 Mirror(horizontally = 1)

Returns a mirrored copy of the image. The parameter horizontally indicates the orientation.

=head2 Replace

This has not yet been implemented.

=head2 Rescale

see Scale();

=head2 Rotate

Rotate is an Image::Magick method. To prevent name conflicts, the Wx::Image compatibility function
has not been implemented. Image::Magick's Rotate knows the following parameters:

=over 4

=item degrees => double

=item color => colorname

=back

=head2 Rotate90(clockwise = 1)

Returns a copy of the image rotated 90 degrees in the direction indicated by clockwise.

=head2 Scale

Scale is an Image::Magick method. To prevent name conflicts, the Wx::Image compatibility function
has not been implemented. Image::Magick's Scale knows the following parameters:

=over 4

=item geometry => geometry

=item width => integer

=item height => integer

=back

=head2 SetData

Sets the image data without performing checks. The data given must have the size (width*height*3) 
or results will be unexpected. Don't use this method if you aren't sure you know what you are doing.

=head2 SetMask(HasMask = 1)

Specifies whether there is a mask or not. 

=head2 SetMaskColour

This sets the transparent color of the current image. For some reason, after setting the MaskColour you
cannot retrieve the color you just set with GetMaskRed, GetMaskGreen and GetMaskBlue. This seems to be a bug in Image::Magick.
If you save the image after setting the MaskColour, it does use the color you indicated for transparency.

=head2 SetMaskFromImage

Not implemented

=head2 SetOption

This is implemented in a different manner than in Wx::Image. It is in fact an alias for Image::Magick's
Set() method. The suggested option 'quality' in the Wx::Image documentation works perfectly with SetOption(quality => 100).
Since this method not documented any further in the wxWidgets documentation, I implemented it this way.

=head2 SetPalette

Not implemented

=head2 SetRGB(x, y, red, green, blue)

Sets the pixel at the given coordinate to the given red, green and blue values.

=head1 Image::Magick compatible METHODS

You can call any Image::Magick method on any Wx::Perl::Imagick object. The module tries to AUTOLOAD the 
Image::Magick method and returns the output immediately. See the documentation of Image::Magick at
L<http://www.imagemagick.org/script/perl-magick.php>

=head1 CONVENIENCE METHODS

There are a few methods I've added that are neither part of Wx::Image, nor of Image::Magick.
They are just for convenience:

=head2 MagickError

If you perform an Image::Magick operation, you may want to call it like this:

    my $img = Wx::Perl::Imagick->new('someimage.jpg');
    $img->MagickError( $img->Resize(geometry => '100x100');

This will output the error if Image::Magick encounters anything.

=head2 SetIndex

If you load an imagefile that contains multiple images, you can call SetIndex to indicate
on which of the images you want to perform the action. For example:

    my $img = Wx::Perl::Imagick->new('pvoice.ico'); # contains 3 different icons
    $img->SetIndex(2); # we want to use the third icon
    my $data = $img->GetData; # now we get only the data from the third icon

=head2 GetIndex

This returns the index we set earlier with SetIndex. 

=head2 GetLoadedImageCount

If we have loaded more than one image, this will return the number of images loaded.

=head1 AUTHOR

Jouke Visser, C<< <jouke@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-wx-perl-imagick@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Wx-Perl-Imagick>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Jouke Visser, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Wx::Perl::Imagick
