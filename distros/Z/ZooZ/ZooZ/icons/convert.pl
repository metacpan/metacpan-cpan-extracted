#!perl -w

use strict;
use Image::Magick;

for my $f (<*.bmp>) {
    my $im = new Image::Magick;
    $im->Read($f);

    my $g = $f;
    $g =~ s/\.bmp/.gif/;
    $im->Write($g);
}
