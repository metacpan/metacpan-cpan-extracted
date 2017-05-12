package XML::NewsML_G2::Picture;

use XML::NewsML_G2::Types;

use Moose;
use namespace::autoclean;

with 'XML::NewsML_G2::Role::RemoteVisual';

has 'rendition', isa => 'Str', is => 'rw', required => 1;
has 'orientation', isa => 'Int', is => 'rw', default => 1;
has 'colorspace', isa => 'Str', is => 'rw';

### XXX move to News_Item, give role, scheme
has 'altId', isa => 'Str', is => 'rw';

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Picture - a picture specification

=head1 SYNOPSIS

    my $pic = XML::NewsML_G2::Picture->new
        (rendition => 'highRes',
         mimetype => 'image/jpg',
         size => 21123
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

= item altId

Alternative identifiers. Optional.

=back

=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
