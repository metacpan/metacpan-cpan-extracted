package XML::NewsML_G2::Role::Remote;

use XML::NewsML_G2::Types;

use Moose::Role;
use namespace::autoclean;

has 'size', isa => 'Int', is => 'rw';
has 'mimetype', isa => 'Str', is => 'rw';

1;
__END__

=head1 NAME

XML::NewsML_G2::Remote - Used by Picture, Graphics, Audio, Video

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

=item mimetype

The MIME type of the video file (e.g. image/jpg)

=back

=head1 AUTHOR

Mario Paumann  C<< <mario.paumann@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
