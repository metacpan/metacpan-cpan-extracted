package WG::API::WoWp;

use Const::Fast;

use Moo;

with 'WG::API::Base';

=head1 NAME

WG::API::WoWp - Module to work with Wargaming.net Public API for World of Warplanes

=head1 VERSION

Version v0.12

=cut

our $VERSION = 'v0.12';

const my $api_uri => '//api.worldofwarplanes.ru/';

sub _api_uri {
    my ($self) = @_;

    return $api_uri;
}

=head1 SYNOPSIS

Wargaming.net Public API is a set of API methods that provide access to Wargaming.net content, including in-game and game-related content, as well as player statistics.

This module provide access to WG Public API

    use WG::API;

    my $wowp = WG::API->new( application_id => 'demo' )->wowp();
    ...
    my $player = $wowp->account_info( account_id => '1' );


=head1 CONSTRUCTOR

=head2 new

Create new object with params. Rerquired application id: L<https://developers.wargaming.net/documentation/guide/getting-started/>

Params:

 - application_id *
 - languare
 - api_uri

=head1 METHODS

=head2 Accounts

=over 1

=item B<account_list( [ %params ] )>

Method returns partial list of players. The list is filtered by initial characters of user name and sorted alphabetically.

=over 2

=item I<required fields:>

    search - Player name search string. Parameter "type" defines minimum length and type of search. Using the exact search type, you can enter several names, separated with commas. Maximum length: 24.

=back

=cut

sub account_list {
    return shift->_request(
        'get', 'wowp/account/list/', [ 'language', 'fields', 'type', 'search', 'limit' ], ['search'],
        @_
    );
}

=item B<account_info( [ %params ] )>

Method returns player details.

=over 2

=item I<required fields:>

    account_id - Account ID. Max limit is 100. Min value is 1.

=back

=cut

sub account_info {
    return shift->_request(
        'get', 'wowp/account/info/', [ 'language', 'fields', 'access_token', 'account_id' ],
        ['account_id'], @_
    );
}

=item B<account_planes( [ %params ] )>

Method returns details on player's aircrafts.

=over 2

=item I<required fields:>

    account_id - Account ID. Max limit is 100. Min value is 1.

=back

=cut

sub account_planes {
    return shift->_request(
        'get', 'wowp/account/planes/', [ 'language', 'fields', 'access_token', 'account_id', 'in_garage', 'plane_id' ],
        ['account_id'], @_
    );
}

=back

=head2 Encyclopedia

=over 1

=item B<encyclopedia_planes( [ %params ] )>

Method returns list of all aircrafts from Encyclopedia

=cut

sub encyclopedia_planes {
    return shift->_request( 'get', 'wowp/encyclopedia/planes/', [ 'fields', 'language', 'nation', 'type' ], undef, @_ );
}

=item B<encyclopedia_planeinfo( [ %params ] )>

Method returns aircraft details from Encyclopedia.

=over 2

=item I<required fields>

    plane_id - aircraft id

=back

=cut

sub encyclopedia_planeinfo {
    return shift->_request( 'get', 'wowp/encyclopedia/planeinfo/', [ 'plane_id', 'fields', 'language' ], ['plane_id'], @_ );
}

=item B<encyclopedia_planemodules( [ %params ] )>

Method returns information from Encyclopedia about modules available for specified aircrafts.

=over 2

=item I<required fields>

    plane_id - aircraft id

=back

=cut

sub encyclopedia_planemodules {
    return shift->_request( 'get', 'wowp/encyclopedia/planemodules/', [ 'plane_id', 'fields', 'language', 'type' ], ['plane_id'], @_ );
}

=item B<encyclopedia_planeupgrades( [ %params ] )>

Method returns information from Encyclopedia about slots of aircrafts and lists of modules which are compatible with specified slots.

=over 2

=item I<required fields>

    plane_id - aircraft id

=back

=cut

sub encyclopedia_planeupgrades {
    return shift->_request( 'get', 'wowp/encyclopedia/planeupgrades/', [ 'plane_id', 'fields', 'language' ], ['plane_id'], @_ );
}

=item B<encyclopedia_planespecification( [ %params ] )>

=over 2

=item I<required fields>

    plane_id - aircraft id

=back

=cut

sub encyclopedia_planespecification {
    return shift->_request( 'get', 'wowp/encyclopedia/planespecification/', [ 'plane_id', 'bind_id', 'fields', 'language', 'module_id' ], ['plane_id'], @_ );
}

=item B<encyclopedia_achievements( [ %params ] )>

Method returns dictionary of achievements from Encyclopedia.

=cut

sub encyclopedia_achievements {
    return shift->_request( 'get', 'wowp/encyclopedia/achievements/', [ 'fields', 'language' ], undef, @_ );
}

=item B<encyclopedia_info( [ %params ] )>

Method returns information about Encyclopedia.

=cut

sub encyclopedia_info {
    return shift->_request( 'get', 'wowp/encyclopedia/info/', undef, undef, @_ );
}

=back

=head2 Ratings

=over 1

=item B<ratings_types( [ %params ] )>

Method returns dictionary of rating periods and ratings details.

=cut

sub ratings_types {
    return shift->_request( 'get', 'wowp/ratings/types/', [ 'language', 'fields' ], undef, @_ );
}

=item B<ratings_accounts( [ %params ] )>

Method returns player ratings by specified IDs.

=over 2

=item I<required fields:>

    account_id - Account ID. Max limit is 100. Min value is 1.
    type - Rating period. For valid values, check the Types of ratings method.

=back

=cut

sub ratings_accounts {
    return shift->_request(
        'get', 'wowp/ratings/accounts/',
        [ 'language', 'fields',       'type', 'date', 'account_id' ],
        [ 'type',     'account_id' ], @_
    );
}

=item B<ratings_neighbors( [ %params ] )>

Method returns list of adjacent positions in specified rating.

=over 2

=item I<required fields:>

    account_id - Account ID. Max limit is 100. Min value is 1.
    type - Rating period. For valid values, check the Types of ratings method.
    rank_field - Rating category.

=back

=cut

sub ratings_neighbors {
    return shift->_request(
        'get', 'wowp/ratings/neighbors/',
        [ 'language', 'fields',     'type',         'date', 'account_id', 'rank_field', 'limit' ],
        [ 'type',     'account_id', 'rank_field' ], @_
    );
}

=item B<ratings_top( [ %params ] )>

Method returns the list of top players by specified parameter.

=over 2

=item I<required fields:>

    type - Rating period. For valid values, check the Types of ratings method.
    rank_field - Rating category.

=back

=cut

sub ratings_top {
    return shift->_request(
        'get', 'wowp/ratings/top/',
        [ 'language', 'fields',       'type', 'date', 'rank_field', 'limit', 'page_no' ],
        [ 'type',     'rank_field' ], @_
    );
}

=item B<ratings_dates( [ %params ] )>

Method returns dates with available rating data.

=over 2

=item I<required fields:>

    type - Rating period. For valid values, check the Types of ratings method.

=back

=cut

sub ratings_dates {
    return shift->_request( 'get', 'wowp/ratings/dates/', [ 'language', 'fields', 'type', 'account_id' ], ['type'], @_ );
}

=back

=head2 Aircraft

=over 1

=item B<planes_stats( [ %params ] )>

Method returns statistics on player's aircraft.

=over 2

=item I<required fields:>

    account_id - Account ID. Max limit is 100. Min value is 1.

=back

=cut

sub planes_stats {
    return shift->_request( 'get', 'wowp/planes/stats/', [ 'account_id', 'access_token', 'fields', 'in_garage', 'language', 'plane_id' ], ['account_id'], @_ );
}

=item B<planes_achievements( [ %params ] )>

Method returns achievements on player's aircraft.

=over 2

=item I<requires_fields:>

        account_id - Account ID. Max limit is 100. Min value is 1.

=back

=cut

sub planes_achievements {
    return shift->_request( 'get', 'wowp/planes/achievements/', [ 'account_id', 'fields', 'language', 'plane_id' ], ['account_id'], @_ );
}

=back

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

1;    # End of WG::API::WoWp

