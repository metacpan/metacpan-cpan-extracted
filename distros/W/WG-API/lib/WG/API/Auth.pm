package WG::API::Auth;

use Moo;
with 'WG::API::Base';

use constant api_uri => 'api.worldoftanks.ru/wot';

=head1 NAME

WG::API::Auth  - Auth-module with using OpenID for work with WG PAPI

=head1 VERSION

Version v0.8.6

=cut

our $VERSION = 'v0.8.6';

=head1 SYNOPSIS

This module implements the possibility of authorization, prolongate and logout from the center of development.

    use WG::API;

    my $response = WG::API->new( application_id => 'demo' )->auth()->login( nofollow => '1', redirect_uri => 'yoursite.com/response' );

    my $redirect_uri = $response->{ 'location' };
    ...

=head1 METHODS

=over 1

=item B<login>

Method authenticates user based on Wargaming.net ID (OpenID) which is used in World of Tanks, World of Tanks Blitz, World of Warplanes, and WarGag.ru. To log in, player must enter email and password used for creating account, or use a social network profile. Authentication is not available for iOS Game Center users in the following cases: the account is not linked to a social network account, or email and password are not specified in the profile.

Information on authorization status is sent to URL specified in redirect_uri parameter.

=back

=cut

sub login {
    my $self = shift;

    return $self->_request( 'get', 'auth/login', [ 'expires_at', 'redirect_uri', 'display', 'nofollow' ], undef, @_ );
}

=over 1

=item B<prolongate>

Method generates new access_token based on the current token.

This method is used when the player is still using the application but the current access_token is about to expire.

=over 2

=item I<required fields:>

    access_token - Access token for the private data of a user's account; can be received via the authorization method; valid within a stated time period

=back

=back

=cut

sub prolongate {
    my $self = shift;

    return $self->_request( 'post', 'auth/prolongate', [ 'access_token', 'expires_at' ], ['access_token'], @_ );
}

=over 1

=item B<logout>

Method deletes user's access_token.

After this method is called, access_token becomes invalid.

=over 2

=item I<required fields:>

    access_token - Access token for the private data of a user's account; can be received via the authorization method; valid within a stated time period

=back

=back

=cut

sub logout {
    my $self = shift;

    return $self->_request( 'post', 'auth/logout', ['access_token'], ['access_token'], @_ );
}

=head1 BUGS

Please report any bugs or feature requests to C<cynovg at cpan.org>, or through the web interface at L<https://github.com/cynovg/WG-API/issues>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WG::API

You can also look for information at:

=over 4

=item * RT: GitHub's request tracker (report bugs here)

L<https://github.com/cynovg/WG-API/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WG-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WG-API>

=item * Search CPAN

L<http://search.cpan.org/dist/WG-API/>

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

1;    # End of WG::API::Auth
