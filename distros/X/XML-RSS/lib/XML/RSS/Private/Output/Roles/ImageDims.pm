package XML::RSS::Private::Output::Roles::ImageDims;

use strict;
use warnings;

sub _out_image_dims {
    my $self = shift;

    # link, image width, image height and description
    return $self->_output_multiple_tags(
        {ext => "image", 'defined' => 1},
        [qw(width height description)],
    );
}

1;

