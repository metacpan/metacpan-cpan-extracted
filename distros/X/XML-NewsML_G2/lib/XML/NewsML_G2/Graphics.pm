package XML::NewsML_G2::Graphics;

use XML::NewsML_G2::Types;

use Moose;
use namespace::autoclean;
use XML::NewsML_G2::Picture;

extends 'XML::NewsML_G2::Picture';

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Graphics - a graphics specification

=head1 SYNOPSIS

    my $pic = XML::NewsML_G2::Graphics->new
        (rendition => 'highRes',
         mimetype => 'application/illustrator',
         size => 21123,
         altId => '1031-14-Wetter',
        );

=head1 ATTRIBUTES

=over 4

=item mimetype

The MIME type of the picture file (e.g. image/jpg)

=item size

The size in bytes of the picture file

= item width

The width in pixel of the picture

= item height

The height in pixel of the picture

= item orientation

The picture orientation (1 is 'upright')

= item colorspace

The colorspace used by this picture (e.g. AdobeRGB)

=back

=head1 AUTHOR

Mario Paumann  C<< <mario.paumann@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
