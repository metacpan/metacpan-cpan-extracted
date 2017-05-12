package XML::NewsML_G2::Audio;

use XML::NewsML_G2::Types;

use Moose;
use namespace::autoclean;

with 'XML::NewsML_G2::Role::RemoteAudible';

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Audio - a audio specification

=head1 SYNOPSIS

    my $pic = XML::NewsML_G2::Audio->new
        (size => 2231259,
         width => 1280,
         height => 720,
         duration => 220,
        );

=head1 ATTRIBUTES

=over 4

=item size

The size in bytes of the audio file

=item duration

The playtime of the audio in seconds

=item audiosamplerate

The sample rate of the audio

=item audiochannels

The number of audio channels (stereo, mono)

=item mimetype

The MIME type of the audio file (e.g. image/jpg)

=back

=head1 AUTHOR

Mario Paumann  C<< <mario.paumann@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
