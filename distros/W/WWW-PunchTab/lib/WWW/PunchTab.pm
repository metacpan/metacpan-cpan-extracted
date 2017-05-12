package WWW::PunchTab;
{
    $WWW::PunchTab::VERSION = '0.02';
}

# ABSTRACT: PunchTab REST API

use strict;
use warnings;
use LWP::UserAgent;
use MIME::Base64;
use JSON;
use Digest::SHA;
use Carp;
use vars qw/$errstr/;
sub errstr { $errstr }

sub new {
    my $class = shift;
    my %args = @_ % 2 ? %{ $_[0] } : @_;

    $args{client_id}  or croak "client_id is required";
    $args{access_key} or croak "access_key is required";
    $args{secret_key} or croak "secret_key is required";
    $args{domain}     or croak "domain is required";
    $args{domain} = 'http://' . $args{domain}
      unless $args{domain} =~ '^https?\://';

    $args{ua} = LWP::UserAgent->new;

    bless \%args, $class;
}

sub sso_auth {
    my $self = shift;
    my %user = @_ % 2 ? %{ $_[0] } : @_;

    my $auth_request = encode_base64( encode_json( \%user ) );
    my $timestamp    = time();
    my $signature    = Digest::SHA::hmac_sha1_hex( "$auth_request $timestamp",
        $self->{secret_key} );

    my $resp = $self->{ua}->post(
        'https://api.punchtab.com/v1/auth/sso',
        'Referer' => $self->{domain},
        'Content' => [
            client_id    => $self->{client_id},
            key          => $self->{access_key},
            auth_request => $auth_request,
            timestamp    => $timestamp,
            signature    => $signature,
        ]
    );
    unless ( $resp->is_success ) {
        $errstr = $resp->status_line;
        return;
    }
    my $data = decode_json( $resp->decoded_content );
    if ( $data->{error} ) {
        $errstr = $data->{error}->{description};
        return;
    }
    $self->{__access_token} = $data->{authResponse}->{accessToken};
    return $data->{authResponse}->{accessToken};
}

sub sso_auth_js {
    my $self = shift;
    my %user = @_ % 2 ? %{ $_[0] } : @_;

    my $auth_request = encode_base64( encode_json( \%user ) );
    $auth_request =~ s/\n//g;
    my $timestamp = time();
    my $signature = Digest::SHA::hmac_sha1_hex( "$auth_request $timestamp",
        $self->{secret_key} );

    return <<JS;
var _pt_pre_config = {
    auth_request: '$auth_request',
    signature: '$signature',
    timestamp: $timestamp,
    client_id: $self->{client_id}
};
JS
}

sub auth_logout {
    my ($self) = @_;

    my $access_token = $self->{__access_token};
    my $resp         = $self->{ua}->post(
        "https://api.punchtab.com/v1/auth/logout",
        'Referer' => $self->{domain},
        'Content' => [
            access_token => $access_token,
            key          => $self->{access_key},
        ]
    );
    my $tmp = __deal_resp($resp);
    return unless $tmp;
    return $tmp->{status};
}

sub auth_status {
    my ( $self, $access_token ) = @_;

    $access_token ||= $self->{__access_token};
    my $resp = $self->{ua}->post(
        "https://api.punchtab.com/v1/auth/status",
        'Referer' => $self->{domain},
        'Content' => [
            access_token => $access_token,
            key          => $self->{access_key},
        ]
    );
    my $tmp = __deal_resp($resp);
    return unless $tmp;
    return $tmp->{status};
}

sub activity {
    my ( $self, $activity_name ) = @_;

    my $url = "https://api.punchtab.com/v1/activity";
    $url .= "/$activity_name" if $activity_name;
    $url .= "?access_token=" . $self->{__access_token};
    my $resp = $self->{ua}->get($url);
    return __deal_resp($resp);
}

sub create_activity {
    my ( $self, $action, $points ) = @_;

# visit, tweet, like, plusone, comment, invite, reply, apply, share, purchase, addtotimeline, search, download, view, checkin, subscribe, and follow
    my $access_token = $self->{__access_token};
    my $resp         = $self->{ua}->post(
"https://api.punchtab.com/v1/activity/$action?access_token=$access_token",
        [ $points ? ( 'points' => $points ) : () ]
    );
    return __deal_resp($resp);
}

sub redeem_reward {
    my ( $self, $reward_id ) = @_;
    my $access_token = $self->{__access_token};
    my $resp         = $self->{ua}->post(
"https://api.punchtab.com/v1/activity/redeem?access_token=$access_token",
        [ reward_id => $reward_id, ]
    );
    return __deal_resp($resp);
}

sub leaderboard {
    my $self         = shift;
    my %args         = @_ % 2 ? %{ $_[0] } : (@_);
    my $access_token = $self->{__access_token};
    my $resp         = $self->{ua}->get(
        "https://api.punchtab.com/v1/leaderboard",
        [
            access_token => $access_token,
            %args,
        ]
    );
    return __deal_resp($resp);
}

sub reward {
    my ( $self, $limit ) = @_;

    my $access_token = $self->{__access_token};
    my $url = "http://api.punchtab.com/v1/reward?access_token=" . $access_token;
    $url .= "&limit=$limit" if $limit;
    my $resp = $self->{ua}->get($url);
    return __deal_resp($resp);
}

sub user {
    my ($self) = @_;

    my $access_token = $self->{__access_token};
    my $resp =
      $self->{ua}
      ->get("https://api.punchtab.com/v1/user?access_token=$access_token");
    return __deal_resp($resp);
}

sub __deal_resp {
    my ($resp) = @_;
    unless ( $resp->is_success ) {
        $errstr = $resp->status_line;
        return;
    }
    my $data = decode_json( $resp->decoded_content );
    if ( ref $data eq 'HASH' and $data->{error} ) {
        $errstr = $data->{error}->{description};
        return;
    }
    return $data;
}

1;

__END__

=pod

=head1 NAME

WWW::PunchTab - PunchTab REST API

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use WWW::PunchTab;
    use Data::Dumper;

    my $pt = WWW::PunchTab->new(
        domain     => 'fayland.org',
        access_key => 'f4f8290698320a98b1044615e722af79',
        client_id  => '1104891876',
        secret_key => 'ed73f70966dd10b7788b8f7953ec1d07',
    );

    $pt->sso_auth(
        {'id' => '2', 'first_name' => 'Fayland', 'last_name' => 'Lam', 'email' => 'fayland@gmail.com'}
    ) or die $pt->errstr;

    my $x = $pt->create_activity('view', 200) or die $pt->errstr; # view with 200 points
    print Dumper(\$x);

=head1 DESCRIPTION

L<http://www.punchtab.com/developer-docs#REST-API-Documentation>

=head2 METHODS

=head3 CONSTRUCTION

    my $pt = WWW::PunchTab->new(
        domain     => 'fayland.org',
        access_key => 'f4f8290698320a98b1044615e722af79',
        client_id  => '1104891876',
        secret_key => 'ed73f70966dd10b7788b8f7953ec1d07',
    );

=over 4

=item * domain

=item * access_key

=item * client_id

=item * secret_key

All required.

=back

=head3 sso_auth

    $pt->sso_auth(
        {'id' => '2', 'first_name' => 'Fayland', 'last_name' => 'Lam', 'email' => 'fayland@gmail.com'}
    ) or die $pt->errstr;

=head3 sso_auth_js

    print $pt->sso_auth_js({'id' => '2', 'first_name' => 'Fayland', 'last_name' => 'Lam', 'email' => 'fayland@gmail.com'});

js sso auth example:

    var _pt_pre_config = {
        auth_request: 'xxx',
        signature: 'xxx',
        timestamp: 1348843966,
        client_id: 123
    };

=head3 auth_logout

    my $status = $pt->auth_logout or die $pt->errstr;

=head3 auth_status

return 'connected' or 'disconnected'

    my $status = $pt->auth_status($access_token) or die $pt->errstr;

=head3 activity

    my $activity = $pt->activity() or die $pt->errstr;
    my $activity = $pt->activity('like') or die $pt->errstr;

=head3 create_activity

     my $x = $pt->create_activity('view', 200) or die $pt->errstr; # view with 200 points

=head3 redeem_reward

     my $x = $pt->redeem_reward($reward_id) or die $pt->errstr;

=head3 leaderboard

     my $leaderboard = $pt->leaderboard() or die $pt->errstr;
     my $leaderboard = $pt->leaderboard(
        with => 'me',
        limit => 20,
        page  => 1,
     ) or die $pt->errstr;

=head3 reward

     my $reward = $pt->reward() or die $pt->errstr;
     my $reward = $pt->reward($limit) or die $pt->errstr;

=head3 user

     my $user = $pt->user() or die $pt->errstr;

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
