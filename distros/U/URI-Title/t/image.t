use warnings;
use strict;
use Test::More;
use URI::Title qw(title);

is(
    title('t/images/camel_head.v25e738a.png'),
    "camel_head.v25e738a.png (png 60x65)",
    "camel_head.v25e738a.png (png 60x65)"
);

SKIP: {
    skip "Image::ExifTool or Image::PNG::Libpng not installed", 1
      unless eval { require Image::ExifTool }
      || eval { require Image::PNG::Libpng };
    is(
        title('t/images/has_title.png'),
        "checker (png 32x32)",
        "checker (png 32x32)"
    );

    is(
        title('t/images/no_title.png'),
        "no_title.png (png 32x32)",
        "no_title.png (png 32x32)"
    );

}

done_testing;
