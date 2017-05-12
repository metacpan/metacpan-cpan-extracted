package XML::NewsML_G2::Role::RemoteAudible;

use XML::NewsML_G2::Types;

use Moose::Role;
use namespace::autoclean;

with 'XML::NewsML_G2::Role::Remote';

has 'duration', isa => 'Str', is => 'rw';
has 'audiosamplerate', isa => 'Int', is => 'rw';
has 'audiochannels', isa => 'Str', is => 'rw';

# IIM :
# 2:150 Audio Type '1A'
# 2:151 Audio Sampling Rate "011025" for a sample rate of 11025 Hz
# 2:152 Audio Sampling Resolution "08" for a sample size of 8 bits
# 2:153 Audio Duration "000105" for a cut lasting one minute, five seconds

1;
__END__

=head1 NAME

XML::NewsML_G2::Remote - Used by Picture, Graphics, Video

=head1 SYNOPSIS

    my $pic = XML::NewsML_G2::Video->new
        (size => 2231259,
         width => 1280,
         height => 720,
         duration => 220,
        );

=head1 ATTRIBUTES

=over 4

=item duration

The playtime of the audio in seconds

=item audiosamplerate

The sample rate of the audio

=item audiochannels

The number of audio channels (stereo, mono)

=item mimetype

The MIME type of the video file (e.g. image/jpg)

=back

=head1 AUTHOR

Mario Paumann  C<< <mario.paumann@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
