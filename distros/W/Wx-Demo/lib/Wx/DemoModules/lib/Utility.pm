#############################################################################
## Name:        lib/Wx/DemoModules/lib/Utility.pm
## Purpose:     wxPerl demo helper
## Author:      Mattia Barbon
## Modified by:
## Created:     03/12/2006
## RCS-ID:      $Id: Utility.pm 2772 2010-02-01 14:23:16Z mdootson $
## Copyright:   (c) 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::lib::Utility;

use strict;
use base qw(Exporter); # for Perl 5.8.1 or earlier

our @EXPORT = qw(resize_to);

sub resize_to {
    my( $image, $size ) = @_;
    # seems not to work on Mac
    return $image if Wx::wxMAC();
    if( $image->GetWidth != $size || $image->GetHeight != $size ) {
        return Wx::Bitmap->new
          ( Wx::Image->new( $image )->Rescale( $size, $size ) );
    } else {
        return $image;
    }
}

1;
