package XML::NewsML_G2::Icon;

use Moose;
use namespace::autoclean;

has 'rendition', isa => 'Str', is => 'rw', required => 1;
has 'href', isa => 'Str', is => 'rw', required => 1;
has 'width', isa => 'Int', is => 'rw';
has 'height', isa => 'Int', is => 'rw';


__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Icon - a preview for a video, can be an image or a video

=head1 SYNOPSIS

    my $org = XML::NewsML_G2::Icon->new
        (rendition => 'Thumbnail', href => 'file:///tmp/123.jpg');

=head1 ATTRIBUTES

=over 4

=item rendition

size of the picture/video

=item href

location of the picture/video

=item width

width of the picture/video

=item height

height of the picture/video

=back

=head1 AUTHOR

Stefan Hrdlicka  C<< <stefan.hrdlicka@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
