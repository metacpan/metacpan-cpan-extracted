package XML::NewsML_G2::Video;

use XML::NewsML_G2::Types;

use Moose;
use namespace::autoclean;

with qw(XML::NewsML_G2::Role::RemoteAudible
    XML::NewsML_G2::Role::RemoteVisual);

has 'videoframerate',  isa => 'Int', is => 'rw';
has 'videoavgbitrate', isa => 'Int', is => 'rw';

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Video - a video specification

=head1 SYNOPSIS

    my $pic = XML::NewsML_G2::Video->new
        (size => 2231259,
         width => 1280,
         height => 720,
         duration => 220,
        );

=head1 ATTRIBUTES

=over 4

=item size

The size in bytes of the video file

=item width

The width in pixel of the video

=item height

The height in pixel of the video

=item duration

The playtime of the video in seconds

=item videoframerate

The frames/second of the video

=item videoavgbitrage

The bit rate of the video

=item audiosamplerate

The sample rate of the audio

=item audiochannels

The number of audio channels (stereo, mono)

=item mimetype

The MIME type of the video file (e.g. image/jpg)

=back

=head1 AUTHOR

Stefan Hrdlicka  C<< <stefan.hrdlicka@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
