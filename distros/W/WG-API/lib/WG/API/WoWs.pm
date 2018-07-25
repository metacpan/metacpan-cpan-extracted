package WG::API::WoWs;

use Const::Fast;

use Moo;

with 'WG::API::Base';

=head1 NAME

WG::API::WoWs - Module for work with Wargaming.net Public API for Worlf of Warships

=head1 VERSION

Version v0.11

=cut

our $VERSION = 'v0.11';

const my $api_uri => '//api.worldofwarships.ru/';

sub _api_uri {
    my ($self) = @_;

    return $api_uri;
}

=head1 SYNOPSIS

Wargaming.net Public API is a set of API methods that provide access to Wargaming.net content, including in-game and game-related content, as well as player statistics.

This module provide access to WG Public API

    use WG::API;

    my $wows = WG::API->new( application_id => 'demo' )->wows();
    ...
    my $player = $wows->account_info( account_id => '1' );

=head1 CONSTRUCTOR

=head2 new 

Create new object with params. Rerquired application id: L<https://developers.wargaming.net/documentation/guide/getting-started/> 

Params:

 - application_id *
 - languare
 - api_uri

=head1 METHODS

=head2 Account

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
        'get', 'wows/account/list/', [ 'language', 'fields', 'type', 'search', 'limit' ], ['search'],
        @_
    );
}

=item B<account_info( [ %params ] )>

Method returns player details. Players may hide their game profiles, use field hidden_profile for determination.

=over 2

=item I<required fields:>

    account_id - Account ID. Max limit is 100. Min value is 1.

=back

=cut

sub account_info {
    return shift->_request(
        'get', 'wows/account/info/', [ 'language', 'fields', 'access_token', 'extra', 'account_id' ],
        ['account_id'], @_
    );
}

=item B<account_achievements( [ %params ] )>

Method returns information about players' achievements. Accounts with hidden game profiles are excluded from response. Hidden profiles are listed in the field meta.hidden.

=cut

sub account_achievements {
    return shift->_request( 'get', 'wows/account/achievements/', [ 'language', 'fields', 'account_id', 'access_token' ], ['account_id'], @_ );
}

=item B<account_statsbydate( [ %params ] )>

Method returns statistics slices by dates in specified time span.

=over 2

=item I<required fields:>

    account_id - Account ID. Max limit is 100. Min value is 1.

=back

=back

=cut

sub account_statsbydate {
    return shift->_request(
        'get', 'wows/account/statsbydate/', [ 'language', 'fields', 'dates', 'access_token', 'extra', 'account_id' ],
        ['account_id'], @_
    );
}

=head2 Encyclopedia

=over 1

=item B<encyclopedia_info( [ %params ] )>

Method returns information about encyclopedia.

=cut

sub encyclopedia_info {
    return shift->_request( 'get', 'wows/encyclopedia/info/', [ 'fields', 'language' ], undef, @_ );
}

=item B<encyclopedia_ships( [ %params ] )>

Method returns list of ships available.

=cut

sub encyclopedia_ships {
    return shift->_request( 'get', 'wows/encyclopedia/ships/', [ 'fields', 'language', 'limit', 'nation', 'page_no', 'ship_id', 'type' ], undef, @_ );
}

=item B<encyclopedia_achievements( [ %params ] )>

Method returns information about achievements.

=cut

sub encyclopedia_achievements {
    return shift->_request( 'get', 'wows/encyclopedia/achievements/', [ 'fields', 'language' ], undef, @_ );
}

=item B<encyclopedia_shipprofile( [ %params ] )>

Method returns parameters of ships in all existing configurations.

=over 2

=item I<required fields>

    ship_id - ship id

=back

=cut

sub encyclopedia_shipprofile {
    return shift->_request(
        'get', 'wows/encyclopedia/shipprofile/',
        [
            'ship_id', 'artillery_id', 'dive_bomber_id',    'engine_id',
            'fields',  'fighter_id',   'fire_control_id',   'flight_control_id',
            'hull_id', 'language',     'torpedo_bomber_id', 'torpedoes_id'
        ],
        ['ship_id'],
        @_
    );
}

=item B<encyclopedia_modules( [ %params ] )>

Method returns list of available modules that can be mounted on a ship (hull, engines, etc.).

=cut

sub encyclopedia_modules {
    return shift->_request( 'get', 'wows/encyclopedia/modules/', [ 'fields', 'language', 'limit', 'module_id', 'page_no', 'type' ], undef, @_ );
}

=item B<encyclopedia_accountlevels( [ %params ] )>

Method returns information about Service Record levels.

=cut

sub encyclopedia_accountlevels {
    return shift->_request( 'get', 'wows/encyclopedia/accountlevels/', ['fields'], undef, @_ );
}

=item B<encyclopedia_crews( [ %params ] )>

Method returns information about Commanders.

=cut

sub encyclopedia_crews {
    return shift->_request( 'get', 'wows/encyclopedia/crews/', [ 'commander_id', 'fields', 'language' ], undef, @_ );
}

=item B<encyclopedia_crewskills( [ %params ] )>

Method returns information about Commangers' skills.

=cut

sub encyclopedia_crewskills {
    return shift->_request( 'get', 'wows/encyclopedia/crewskills/', [ 'fields', 'language', 'skill_id' ], undef, @_ );
}

=item B<encyclopedia_crewranks( [ %params ] )>

Method returns information about Commanders' skills.

=cut

sub encyclopedia_crewranks {
    return shift->_request( 'get', 'wows/encyclopedia/crewranks/', [ 'fields', 'language', 'nation' ], undef, @_ );
}

=item B<encyclopedia_battletypes( [ %params ] )>

Method returns information about battle types.

=cut

sub encyclopedia_battletypes {
    return shift->_request( 'get', 'wows/encyclopedia/battletypes/', [ 'fields', 'language' ], undef, @_ );
}

=item B<encyclopedia_consumables( [ %params ] )>

Method returns information about consumables: camouflages, flags, and upgrades.

=cut

sub encyclopedia_consumables {
    return shift->_request( 'get', 'wows/encyclopedia/consumables/', [ 'consumable_id', 'fields', 'language', 'limit', 'page_no', 'type' ], undef, @_ );
}

=item B<encyclopedia_collections( [ %params ] )>

Method returns information about collections.

=cut

sub encyclopedia_collections {
    return shift->_request( 'get', 'wows/encyclopedia/collections/', [ 'fields', 'language' ], undef, @_ );
}

=item B<encyclopedia_collectioncards( [ %params ] )>

Method returns information about items that are included in the collection.

=cut

sub encyclopedia_collectioncards {
    return shift->_request( 'get', 'wows/encyclopedia/collectioncards/', [ 'fields', 'language' ], undef, @_ );
}

=item B<encyclopedia_battlearenas( [ %params ] )>

Method returns the information about maps.

=cut

sub encyclopedia_battlearenas {
    return shift->_request( 'get', 'wows/encyclopedia/battlearenas/', [ 'fields', 'language' ], undef, @_ );
}

=back

=head2 Warships

=over 1

=item B<ships_stats( [ %params ] )>

Method returns general statistics for each ship of a player. Accounts with hidden game profiles are excluded from response. Hidden profiles are listed in the field meta.hidden.

=over 2

=item I<required fields:>

    account_id - Account ID. Max limit is 100. Min value is 1.

=back

=back

=cut

sub ships_stats {
    return shift->_request(
        'get', 'wows/ships/stats/',
        [ 'language', 'fields', 'access_token', 'extra', 'account_id', 'ship_id', 'in_garage' ],
        ['account_id'], @_
    );
}

=head2 Seasons

=over 1

=item B<seasons_info( [ %params ] )>

=cut

sub seasons_info {
    return shift->_request( 'get', 'wows/seasons/info/', [ 'fields', 'language', 'season_id' ], [], @_ );
}

=item B<seasons_shipstats( [ %params ] )>

Method returns players' ships statistics in Ranked Battles seasons. Accounts with hidden game profiles are excluded from response. Hidden profiles are listed in the field meta.hidden.

=over 2

=item I<required_fields:>

    account_id - Account ID. Max limit is 100. Min value is 1.

=back

=cut

sub seasons_shipstats {
    return shift->_request( 'get', 'wows/seasons/shipstats/', [ 'account_id', 'access_token', 'fields', 'language', 'season_id', 'ship_id' ], ['account_id'], @_ );
}

=item B<seasons_accountinfo( [ %params ] )>

Method returns players' statistics in Ranked Battles seasons. Accounts with hidden game profiles are excluded from response. Hidden profiles are listed in the field meta.hidden.

=over 2

=item I<required_fields:>

    account_id - Account ID. Max limit is 100. Min value is 1.

=back

=back

=cut

sub seasons_accountinfo {
    return shift->_request( 'get', 'wows/seasons/accountinfo/', [ 'account_id', 'access_token', 'fields', 'language', 'season_id' ], ['account_id'], @_ );
}

=head2 Clans

=over 1

=item B<clans( [ %params ] )>

Method searches through clans and sorts them in a specified order

=cut

sub clans {
    return shift->_request( 'get', 'wows/clans/list/', [ 'fields', 'language', 'limit', 'page_no', 'search' ], [], @_ );
}

=item B<clans_details( [ %params ] )>

Method returns detailed clan information

=over 2

=item I<required_fields:>

    clan_id - Clan ID. Max limit is 100.

=back

=cut

sub clans_details {
    return shift->_request( 'get', 'wows/clans/info/', [ 'clan_id', 'extra', 'fields', 'language' ], ['clan_id'], @_ );
}

=item B<clans_accountinfo( [ $params ] )>

Method returns player clan data. Player clan data exist only for accounts, that were participating in clan activities: sent join requests, were clan members etc.

=over 2

=item I<required_fields:>

    account_id - Account ID. Max limit is 100. Min value is 1.

=back

=cut

sub clans_accountinfo {
    return shift->_request( 'get', 'wows/clans/accountinfo/', [ 'account_id', 'extra', 'fields', 'language' ], ['account_id'], @_ );
}

=item B<clans_glossary( [ %params ] )>

Method returns information on clan entities.

=cut

sub clans_glossary {
    return shift->_request( 'get', 'wows/clans/glossary/', [ 'fields', 'language' ], [], @_ );
}

=item B<clans_season( [ %params ] )>

Method returns information about Clan Battles season.

=back

=cut

sub clans_season {
    return shift->_request( 'get', 'wows/clans/season/', [ 'fields', 'language' ], [], @_ );
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

1;    # End of WG::API::WoWs

