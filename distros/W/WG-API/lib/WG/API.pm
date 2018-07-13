package WG::API;

use Modern::Perl '2015';
use Moo;

=encoding utf8

=head1 NAME

WG::API - Module for work with Wargaming.net Public API

=head1 VERSION

Version v0.10

=cut

our $VERSION = 'v0.10';

=head1 SYNOPSIS

Wargaming.net Public API is a set of API methods that provide access to Wargaming.net content, including in-game and game-related content, as well as player statistics.

This module provide access to WG Public API

    use WG::API;

    my $wg = WG::API->new( application_id => 'demo' );
    ...
    my $player = $wg->net( language => 'en' )->account_info( account_id => '1' );

=head1 ATTRIBUTES

=over 1

=item I<application_id*>

Rerquired application id: L<https://developers.wargaming.net/documentation/guide/getting-started/>

=back

=cut 

has application_id => (
    is      => 'ro',
    require => 1,
);

=head1 METHODS

=over 1

=item B<wot>

Returns a WoT instance

=back

=cut

#@returns WG::API::WoT
sub wot {
    my $self = shift;

    require WG::API::WoT;

    return WG::API::WoT->new(
        application_id => $self->application_id,
        @_,
    );
}

=over 1

=item B<wowp>

Returns A WoWp instance

=back

=cut

#@returns WG::API::WoWp
sub wowp {
    my $self = shift;

    require WG::API::WoWp;

    return WG::API::WoWp->new(
        application_id => $self->application_id,
        @_,
    );
}

=over 1

=item B<wows>

Returns a WoWs instance

=back

=cut

#@returns WG::API::WoWs
sub wows {
    my $self = shift;

    require WG::API::WoWs;

    return WG::API::WoWs->new(
        application_id => $self->application_id,
        @_,
    );
}

=over 1

=item B<net>

Returns a NET instance

=back

=cut

#@returns WG::API::NET
sub net {
    my $self = shift;

    require WG::API::NET;

    return WG::API::NET->new(
        application_id => $self->application_id,
        @_,
    );
}

=over 1

=item B<auth>

Return a Auth instance

=back

=cut

#@returns WG::API::Auth
sub auth {
    my $self = shift;

    require WG::API::Auth;

    return WG::API::Auth->new(
        application_id => $self->application_id,
        @_,
    );
}

=head1 BUGS

Please report any bugs or feature requests to C<cynovg at cpan.org>, or through the web interface at L<https://gitlab.com/cynovg/WG-API/issues>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WG::API

You can also look for information at:

=over 4

=item * RT: Gitlab's request tracker (report bugs here)

L<https://gitlab.com/cynovg/WG-API/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WG-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WG-API>

=item * Search CPAN

L<https://metacpan.org/pod/WG::API>

=back


=head1 ACKNOWLEDGEMENTS

...

=head1 SEE ALSO

WG API Reference L<https://developers.wargaming.net/>

=head1 AUTHOR

Cyrill Novgorodcev , C<< <cynovg at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Cyrill Novgorodcev.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of WG::API
