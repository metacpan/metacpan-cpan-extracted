# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2011-2021, Roland van Ipenburg
package WWW::NOS::Open::Video v1.0.5;
use strict;
use warnings;

use utf8;
use 5.014000;

use Moose qw/extends/;
use namespace::autoclean '-also' => qr/^__/sxm;

extends 'WWW::NOS::Open::MediaResource';

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=for stopwords Bitbucket DateTime URI perl Ipenburg MERCHANTABILITY

=head1 NAME

WWW::NOS::Open::Video - client side video in the Open NOS REST API.

=head1 VERSION

This document describes WWW::NOS::Open::Video version C<v1.0.5>.

=head1 SYNOPSIS

    use WWW::NOS::Open::Video;

=head1 DESCRIPTION

This class represents a video as returned in the latest ten videos list.

=head1 SUBROUTINES/METHODS

=head2 C<new>

Create a new video object.

=over

=item 1. A hash containing the properties and their values.

=back

=head2 C<get_id>

Returns the id of the video as integer.

=head2 C<get_title>

Returns the title of the video as string.

=head2 C<get_description>

Returns the description of the video as string.

=head2 C<get_published>

Returns the publishing date of the video as a L<DateTime|DateTime> object.

=head2 C<get_last_update>

Returns the date of the last update for the video as a L<DateTime|DateTime>
object.

=head2 C<get_thumbnail_xs>

Returns the URL of the extra small thumbnail for the video as an L<URI|URI>
object.

=head2 C<get_thumbnail_s>

Returns the URL of the small thumbnail for the video as an L<URI|URI> object.

=head2 C<get_thumbnail_m>

Returns the URL of the medium sized thumbnail for the video as an L<URI|URI>
object.

=head2 C<get_link>

Returns the URL of the video as an L<URI|URI> object. 

=head2 C<get_embed_code>

Return the HTML code to embed the video in an HTML page.

=head2 C<get_keywords>

Returns the list of keywords for the video as a reference to an array of
strings.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over 4

=item * perl 5.14 

=item * L<Moose|Moose>

=item * L<WWW::NOS::Open::MediaResource|WWW::NOS::Open::MediaResource>

=item * L<namespace::autoclean|namespace::autoclean>

=back

=head1 INCOMPATIBILITIES

=head1 DIAGNOSTICS

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests at
L<Bitbucket|https://bitbucket.org/rolandvanipenburg/www-nos-open/issues>.

=head1 AUTHOR

Roland van Ipenburg, E<lt>roland@rolandvanipenburg.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2021 by Roland van Ipenburg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
