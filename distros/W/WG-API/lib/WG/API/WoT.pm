package WG::API::WoT;

use Moo;

with 'WG::API::Base';

=head1 NAME

WG::API::WoT - Modules to work with Wargaming.net Public API for World of Tanks

=head1 VERSION

Version v0.8.6

=cut

our $VERSION = 'v0.8.6';

use constant api_uri => 'api.worldoftanks.ru/wot';

=head1 SYNOPSIS

Wargaming.net Public API is a set of API methods that provide access to Wargaming.net content, including in-game and game-related content, as well as player statistics.

This module provide access to WG Public API

    use WG::API;

    my $wot = WG::API->new( application_id => 'demo' )->wot();
    ...
    my $player = $wot->account_info( account_id => '1' );



=head1 CONSTRUCTOR

=head2 new

Create new object with params. Rerquired application id: L<https://developers.wargaming.net/documentation/guide/getting-started/>

Params:

 - application_id *
 - languare
 - api_uri

=head1 METHODS

=head2 Account

=head3 B<account_list( [ %params ] )>

Method returns partial list of players. The list is filtered by initial characters of user name and sorted alphabetically

=cut

sub account_list {
    my $self = shift;

    return $self->_request( 'get', 'account/list', [ 'language', 'fields', 'type', 'search', 'limit' ], ['search'],
        @_ );
}

=head3 B<account_info( [ %params ] )>

Method returns player details.

=cut

sub account_info {
    my $self = shift;

    return $self->_request( 'get', 'account/info', [ 'language', 'fields', 'access_token', 'extra', 'account_id' ],
        ['account_id'], @_ );
}

=head3 B<account_tanks( [ %params ] )>

Method returns details on player's vehicles.

=cut

sub account_tanks {
    my $self = shift;

    return $self->_request( 'get', 'account/tanks', [ 'language', 'fields', 'access_token', 'account_id', 'tank_id' ],
        ['account_id'], @_ );
}

=head3 B<account_achievements( [ %params ] )>

Method returns players' achievement details.

Achievement properties define the achievements field values:

    1-4 for Mastery Badges and Stage Achievements (type: "class");
    maximum value of Achievement series (type: "series");
    number of achievements earned from sections: Battle Hero, Epic Achievements, Group Achievements, Special Achievements, etc. (type: "repeatable, single, custom").

=cut

sub account_achievements {
    my $self = shift;

    return $self->_request( 'get', 'account/achievements', [ 'language', 'fields', 'account_id' ], ['account_id'], @_ );
}

=head2 Player's vehicles

=head3 B<tanks_stats( [ %params ] )>

Method returns overall statistics, Tank Company statistics, and clan statistics per each vehicle for each user.

=cut

sub tanks_stats {
    my $self = shift;

    return $self->_request( 'get', 'tanks/stats',
        [ 'language', 'fields', 'access_token', 'account_id', 'tank_id', 'in_garage' ],
        ['account_id'], @_ );
}

=head3 B<tanks_achievements( [ %params ] )>

Method returns list of achievements on all vehicles.

Achievement properties define the achievements field values:

    1-4 for Mastery Badges and Stage Achievements (type: "class");
    maximum value of Achievement series (type: "series");
    number of achievements earned from sections: Battle Hero, Epic Achievements, Group Achievements, Special Achievements, etc. (type: "repeatable, single, custom").

=cut

sub tanks_achievements {
    my $self = shift;

    return $self->_request( 'get', 'tanks/achievements',
        [ 'language', 'fields', 'access_token', 'account_id', 'tank_id', 'in_garage' ],
        ['account_id'], @_ );
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

1;    # End of WG::API::WoT
