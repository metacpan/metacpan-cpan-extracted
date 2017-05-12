package WWW::Foursquare;

use 5.006;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.9906';

use WWW::Foursquare::Config;
use WWW::Foursquare::Request;

use WWW::Foursquare::Users;
use WWW::Foursquare::Venues;
use WWW::Foursquare::Venuegroups;
use WWW::Foursquare::Checkins;
use WWW::Foursquare::Tips;
use WWW::Foursquare::Lists;
use WWW::Foursquare::Updates;
use WWW::Foursquare::Photos;
use WWW::Foursquare::Settings;
use WWW::Foursquare::Specials;
use WWW::Foursquare::Campaigns;
use WWW::Foursquare::Events;
use WWW::Foursquare::Pages;
use WWW::Foursquare::Pageupdates;

use JSON;
use LWP;
use URI::Escape;

sub new {
    my ($class, %params) = @_;
    
    my $self = {};
    bless $self, $class;
    $self->{client_id}     = $params{client_id};
    $self->{client_secret} = $params{client_secret};
    $self->{debug}         = $params{debug};
    $self->{redirect_uri}  = $params{redirect_uri};
    $self->{request}       = WWW::Foursquare::Request->new(\%params);
    
    return $self;
}

sub get_auth_url {
    my $self = shift;

    my $params = { 
        client_id     => $self->{client_id},
        redirect_uri  => $self->{redirect_uri},
        response_type => 'code',
    };
    my $query = _params_to_str( $params ); 
    my $url   = sprintf "%s?%s", $AUTH_CODE_ENDPOINT, $query;

    return $url;
}

sub get_access_token {
    my ($self, $code) = @_;

    my $params = {
        client_id     => $self->{client_id},
        client_secret => $self->{client_secret},
        code          => $code, 
        grant_type    => 'authorization_code',
        redirect_uri  => $self->{redirect_uri},
    };

    my $res = $self->_get($ACCESS_TOKEN_ENDPOINT, $params);
    return $res->{access_token};
}

sub set_access_token {
    my ($self, $access_token) = @_;

    warn "access_token: $access_token" if $self->{debug};

    # update params of request
    $self->{request}->{access_token} = $access_token;
    $self->{request}->{userless}     = $access_token 
                                        ? 0 
                                        : 1; 
}

sub users {
    my ($self, $user_id) = @_;

    return WWW::Foursquare::Users->new($self->{request}, $user_id);
}

sub venues {
    my ($self, $venue_id) = @_;

    return WWW::Foursquare::Venues->new($self->{request}, $venue_id);
}

sub venuegroups {
    my ($self, $group_id) = @_;

    return WWW::Foursquare::Venuegroups->new($self->{request}, $group_id);
}

sub checkins {
    my ($self, $checkin_id) = @_;

    return WWW::Foursquare::Checkins->new($self->{request}, $checkin_id);
}

sub tips {
    my ($self, $tip_id) = @_;

    return WWW::Foursquare::Tips->new($self->{request}, $tip_id);
}

sub lists {
    my ($self, $list_id) = @_;

    return WWW::Foursquare::Lists->new($self->{request}, $list_id);
}

sub updates {
    my ($self, $update_id) = @_;

    return WWW::Foursquare::Updates->new($self->{request}, $update_id);
}

sub photos {
    my ($self, $photo_id) = @_;

    return WWW::Foursquare::Photos->new($self->{request}, $photo_id);
}

sub settings {
    my ($self, $setting_id) = @_;

    return WWW::Foursquare::Settings->new($self->{request}, $setting_id);
}

sub campaigns {
    my ($self, $campaign_id) = @_;

    return WWW::Foursquare::Campaigns->new($self->{request}, $campaign_id);
}

sub events {
    my ($self, $event_id) = @_;
    
    return WWW::Foursquare::Events->new($self->{request}, $event_id);
}

sub pages {
    my ($self, $page_id) = @_;

    return WWW::Foursquare::Pages->new($self->{request}, $page_id);
}

sub pageupdates {
    my ($self, $update_id) = @_;

    return WWW::Foursquare::Pageupdates->new($self->{request}, $update_id);
}

sub _params_to_str {
    my $hash = shift;

    my $str = join '&', map { $_.'='.uri_escape($hash->{$_}) } sort keys %$hash;
    return $str;
}

sub _get {
    my ($self, $url, $params) = @_;

    my $query      = _params_to_str($params);
    my $result_url = sprintf "%s?%s", $url, $query;

    warn "$result_url" if $self->{debug};

    my $res = $self->{request}->{ua}->get($result_url);

    return decode_json($res->content()) if $res->code() == 200;

    # throw exception
    die $res->content();
}

sub _ua {
    my ($self) = @_;

    return $self->{request}->{ua};
}


1;

=head1 NAME

WWW::Foursquare - is a Perl wrapper for the Foursqauare API.

=head1 VERSION

This document describes WWW::Foursquare version 0.9906

=cut

=head1 SYNOPSIS

    use WWW::Foursquare;

    # Create fs object
    my $fs = WWW::Foursquare->new(
        client_id     => 'client_id',
        client_secret => 'client_secret',
        redirect_uri  => 'redirect_uri',
    );

    # Set access_token
    my $access_token = 'XXXX';
    $fs->set_token($access_token);

    # Search users by name
    my $search_users = eval { $fs->users()->search(name => 'Pavel Vlasov') };

    if (not $@) {
    
        # work with result in Perl structure
        # print Dumper($search_users);
    }
    else {

        # process errors
        warn $@ if $@;
    }

=cut

=head1 DESCRIPTION

This wrapper help you send requests to Foursquare API and get result in easy way, OAuth is supported, quick integration with your current project.
You can get more information about Foursquare API here: L<https://developer.foursquare.com/> 

=head1 INTEGRATION

How to connect your apps with foursquare via OAuth 2.0.

=head2 1. Create foursquare app: 

https://foursquare.com/developers/apps

Get Client ID, Client Secret and Callback url

    my $fs = WWW::Foursquare->new(
        client_id     => 'client_id',
        client_secret => 'client_secret',
        redirect_uri  => 'redirect_uri',
    );

=head2 2. Get auth url for your apps:

    my $auth_url = $fs->get_auth_url();
    It looks like this: https://foursquare.com/oauth2/authenticate?client_id=client_id&redirect_uri=redirect_url&response_type=code

=head2 3. Have a user authorize your app.

Implement callback in your server. 

- You click on auth url to go to autorize page. 
- If authorization is successful you will redirect to callback url and get code.
- Then you use this code for getting access_token for Foursquare API 

    http://your_server.com/callback&code=XXXXXXX
    my $code = ... # getting code here

Allow app to access to your account in foursquare

    my $access_token = $fs->get_access_token($code);

Background magic will send GET request to Foursquare API 

=head2 4. Set access_token and using Foursquare API

    $fs->set_access_token($access_token);

For more information I would recommend you visit page L<https://developer.foursquare.com/overview/auth>

=head1 DEBUG MODE

    my $fs = WWW::Foursquare->new(
        debug => 1,
    );

=head1 METHODS

=head2 new

Creating a new foursquare object.

    my $fs = WWW::Foursquare->new(
        client_id     => 'client_id',
        client_secret => 'client_secret',
        redirect_uri  => 'redirect_uri',
    );

=head2 get_auth_url

Prepare auth url from Foursquare parameters (cliend_id, redirect_uri)

    my $auth_url = $fs->get_auth_url();

=head2 get_access_token

Get code after redirect, and send GET request to fetch access token

    my $access_token = $fs->get_access_token($code);

=head2 set_access_token
    
Set access token for foursquare object

    $fs->set_access_token($code);

=head2 users

All users methods: https://developer.foursquare.com/docs/users/users
    
If you want to use itself method for forsquare API:

    $fs->users->info(); # get info about users etc

=head2 venues

All venues methods: https://developer.foursquare.com/docs/venues/venues

=head2 venuegroups

All venuegroups methods: https://developer.foursquare.com/docs/venuegroups/venuegroups

=head2 checkins

All checkins methods: https://developer.foursquare.com/docs/checkins/checkins

=head2 tips

All tips methods: https://developer.foursquare.com/docs/tips/tips

=head2 lists

All lists methods: https://developer.foursquare.com/docs/lists/lists

=head2 updates

All updates methods: https://developer.foursquare.com/docs/updates/updates

=head2 photos

All photos methods: https://developer.foursquare.com/docs/photos/photos

=head2 settings
    
All settings methods: https://developer.foursquare.com/docs/settings/settings

=head2 specials
    
All specials methods: https://developer.foursquare.com/docs/specials/specials

=head2 campaigns

All campaigns methods: https://developer.foursquare.com/docs/campaigns/campaigns

=head2 events

All events methods: https://developer.foursquare.com/docs/events/events

=head2 pages

All pages methods: https://developer.foursquare.com/docs/pages/pages

=head2 pageupdates

All pageupdates methods: https://developer.foursquare.com/docs/pageupdates/pageupdates

=head1 EXAMPLES

You can see examples how to use WWW::Foursquare. 
Here: /eg/test.pl

=head1 AUTHOR

Pavel Vlasov, C<< <fxzuz at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-foursquare at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Foursquare>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Foursquare


You can also look for information at:

=over 5

=item * Github

L<http://github.com/fxzuz/WWW-Foursquare/>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Foursquare>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Foursquare>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Foursquare>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Foursquare/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Pavel Vlasov.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
