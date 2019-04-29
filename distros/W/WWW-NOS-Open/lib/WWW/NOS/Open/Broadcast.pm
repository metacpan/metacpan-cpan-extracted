package WWW::NOS::Open::Broadcast v1.0.2; # -*- cperl; cperl-indent-level: 4 -*-
use strict;
use warnings;

use utf8;
use 5.014000;

use Moose qw/around has with/;
use Moose::Util::TypeConstraints qw/enum/;
use namespace::autoclean '-also' => qr/^__/sxm;

use WWW::NOS::Open::TypeDef qw(NOSDateTime NOSURI);

use Readonly;
Readonly::Scalar my $UNDER              => q{_};
Readonly::Scalar my $GETTER             => q{get};
Readonly::Array my @TV_CHANNEL_CODES    => qw(NL1 NL2 NL3);
Readonly::Array my @RADIO_CHANNEL_CODES => qw(RA1 RA2 RA3 RA4 RA5 RA6);

has '_id' => (
    'is'       => 'ro',
    'isa'      => 'Int',
    'reader'   => 'get_id',
    'init_arg' => 'id',
);

has '_channel_icon' => (
    'is'       => 'ro',
    'isa'      => NOSURI,
    'coerce'   => 1,
    'reader'   => 'get_channel_icon',
    'init_arg' => 'channel_icon',
);

my @dates = qw(starttime endtime);
while ( my $date = shift @dates ) {
    has $UNDER
      . $date => (
        'is'       => 'ro',
        'isa'      => NOSDateTime,
        'coerce'   => 1,
        'reader'   => $GETTER . $UNDER . $date,
        'init_arg' => $date,
      );
}

has '_channel_code' => (
    'is'       => 'ro',
    'isa'      => enum( [ @TV_CHANNEL_CODES, @RADIO_CHANNEL_CODES ] ),
    'reader'   => 'get_channel_code',
    'init_arg' => 'channel_code',
);

my @strings = qw(type channel_name genre title description);
while ( my $string = shift @strings ) {
    has $UNDER
      . $string => (
        'is'       => 'ro',
        'isa'      => 'Str',
        'reader'   => $GETTER . $UNDER . $string,
        'init_arg' => $string,
      );
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=for stopwords DateTime URI Ipenburg MERCHANTABILITY

=head1 NAME

WWW::NOS::Open::Broadcast - client side broadcasts in the Open NOS REST API.

=head1 VERSION

This document describes WWW::NOS::Open::Broadcast version v1.0.2.

=head1 SYNOPSIS

    use WWW::NOS::Open::Broadcast;

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<new>

Create a new WWW::NOS::Open::Broadcast object.

=over

=item 1. A hash containing the properties and their values.

=back

=head2 C<get_id>

Returns the id of the article as integer.

=head2 C<get_title>

Returns the title of the article as string.

=head2 C<get_description>

Returns the description of the article as string.

=head2 C<get_published>

Returns the publishing date of the article as a L<DateTime|DateTime> object.

=head2 C<get_last_update>

Returns the date of the last update for the article as a L<DateTime|DateTime>
object.

=head2 C<get_thumbnail_xs>

Returns the URL of the extra small thumbnail for the article as an L<URI|URI>
object.

=head2 C<get_thumbnail_s>

Returns the URL of the small thumbnail for the article as an L<URI|URI> object.

=head2 C<get_thumbnail_m>

Returns the URL of the medium sized thumbnail for the article as an L<URI|URI>
object.

=head2 C<get_link>

Returns the URL of the main article as an L<URI|URI> object. 

=head2 C<get_keywords>

Returns the list of keywords for the article as a reference to an array of
strings.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over 4

=item * L<DateTime|DateTime>

=item * L<Date::Parse|Date::Parse>

=item * L<URI|URI>

=item * L<Moose|Moose>

=item * L<Moose::Util::TypeConstraints|Moose::Util::TypeConstraints>

=item * L<namespace::autoclean|namespace::autoclean>

=back

=head1 INCOMPATIBILITIES

=head1 DIAGNOSTICS

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests at
L<RT for rt.cpan.org|https://rt.cpan.org/Dist/Display.html?Queue=WWW-NOS-Open>.

=head1 AUTHOR

Roland van Ipenburg, E<lt>ipenburg@xs4all.nlE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 by Roland van Ipenburg

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
