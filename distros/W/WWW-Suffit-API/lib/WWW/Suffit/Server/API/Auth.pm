package WWW::Suffit::Server::API::Auth;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Server::API::Auth - The authentication and authorization Suffit API controller

=head1 SYNOPSIS

    use WWW::Suffit::Server::API::Auth;

=head1 DESCRIPTION

The authentication and authorization Suffit API controller

=head1 METHODS

List of authorization/authentication methods

=head2 authorize

    $c->routes->post('/authorize')->to('API::Auth#authorize'
      => {token_type => 'session'});
    $c->routes->post('/authorize')->to('API::Auth#authorize'
      => {token_type => 'access'});
    $c->routes->post('/authorize')->to('API::Auth#authorize'
      => {token_type => 'api'});

The authorization controller  by stashed parameters

Options:

=over 8

=item skip_authdb_connect

    skip_authdb_connect => 1

This option disables connection to authorization database

=item token_type

    token_type => 'access'

This option is required and sets the token type: C<access>, C<session>, C<refresh> or C<api>

=back

See L</"POST /authorize">

=head2 is_authorized

    my $authorized = $c->routes->under('/api')->to('API::Auth#is_authorized')
         ->name('api');

The API Authorization checker. If use `init_api_routes` startup option then
this route will be exists by default. To get access to this route use:

    my $authorized = $r->lookup('api');

=head1 API METHODS

List of API methods

=head2 POST /api/authorize

This method performs authentication and authorization on the Suffit API server,
then returns the access token

    # curl -v -X POST \
      -H "Accept: application/json" \
      -d '{
        "username": "test",
        "password": "test",
        "encrypted": false,
        "remember": false,
        "cachekey": ""
      }' \
      https://localhost:8695/api/authorize

    # curl -v -X POST \
      -H "Accept: application/json" \
      -F username=test -F password=test \
      https://localhost:8695/api/authorize

    > POST /authorize HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: application/json
    > Content-Length: 248
    > Content-Type: multipart/form-data; boundary=-----6a21ca7cea8dc981
    >
    < HTTP/1.1 200 OK
    < Date: Tue, 13 Aug 2024 14:42:56 GMT
    < Content-Type: application/json;charset=UTF-8
    < Content-Length: 635
    < Server: WWW::Suffit/1.00
    <
    {
      "cachekey": "97vyZgPzskPG",
      "clientid": "f459f12619c961122450ae5883e44a60",
      "code": "E0000",
      "datetime": "2024-08-13T14:42:56Z",
      "elapsed": 0.230106,
      "encrypted": false,
      "expires": "2024-08-14T14:42:56Z",
      "jti": "oWwGYKT2MdKj-xVvF9s9",
      "message": "The user is successfully authorized",
      "referer": "",
      "status": true,
      "token": "ey...8o",
      "type": "access",
      "user": {
        "algorithm": "SHA256",
        "attributes": "",
        "comment": "Test user for internal testing only",
        "created": 1678741533,
        "email": "test@owl.localhost",
        "email_md5": "163e50783979333ebae6fd63b2d96d16",
        "expires": 1723560176,
        "flags": 31,
        "groups": [
          "user"
        ],
        "name": "Test User",
        "not_after": 0,
        "not_before": 1695334721,
        "public_key": "-----BEGIN RSA PUBLIC KEY-----...",
        "role": "Test user",
        "uid": 3,
        "username": "test"
      }
    }

=head1 ERROR CODES

List of authentication and authorization Suffit API error codes

    API   | HTTP  | DESCRIPTION
   -------+-------+-------------------------------------------------
    E1000   [403]   Access denied. No token/session exists
    E1001   [403]   Access denied. JWT error
    E1002   [403]   Access denied. The token has been revoked
    E1003   [ * ]   Access denied. Session is not authorized
    E1004   [ * ]   Access denied by realm restrictions
    E1005   [500]   The authorization database is not ready
    E1006   [500]   Can't connect to authorization database
    E1007   [---]   Reserved
    E1008   [---]   Reserved
    E1009   [---]   Reserved
    E1010   [---]   Reserved
    E1011   [---]   Reserved
    E1012   [---]   Reserved
    E1013   [---]   Reserved
    E1014   [---]   Reserved
    E1015   [---]   Reserved
    E1016   [---]   Reserved
    E1017   [---]   Reserved
    E1018   [---]   Reserved
    E1019   [---]   Reserved
    E1020   [400]   Incorrect token type
    E1021   [401]   No username specified
    E1022   [401]   No password specified
    E1023   [500]   RSA decode error
    E1024   [500]   Can't JWT generate
    E1025   [500]   Can't token store to database
    E1026   [---]   Reserved
    E1027   [---]   Reserved
    E1028   [---]   Reserved
    E1029   [---]   Reserved

B<*> -- this code will be defined later on the interface side

See also list of common Suffit API error codes in L<WWW::Suffit::API/"ERROR CODES">

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<WWW::Suffit::Server>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2025 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON qw / true false /;
use Mojo::Util qw/ md5_sum /;
use Mojo::Date;
use Mojo::URL;
use Mojo::JSON qw / true false /;

use Acrux::Util qw/ parse_time_offset randchars /;
use Acrux::RefUtil qw/ is_true_flag /;

use WWW::Suffit::Const qw/ TOKEN_EXPIRATION TOKEN_EXPIRE_MAX /;
use WWW::Suffit::RSA;

sub is_authorized {
    my $self = shift;
    my ($username, $expiration, $cachekey);

    # Get authdb instance
    my $authdb = $self->authdb;

    # Get authorization data from token (if specified)
    if (my $token = $self->token) {
        my $jwt = $self->jwt;

        # Get payload from JWT
        my $payload = $jwt->decode($token)->payload;
        if ($jwt->error) {
            $self->reply->json_error(403 => "E1001" => sprintf("Access denied. %s", $jwt->error));
            return;
        }
        $username = $payload->{'usr'};
        $expiration = $payload->{'exp'} || (time + TOKEN_EXPIRATION);
        $cachekey = $payload->{'key'};

        # Check the token by database
        if ($payload->{'jti'}) {
            unless ($authdb->token_check($username, $payload->{'jti'})) {
                if ($authdb->error) {
                    $self->reply->json_error($authdb->code, $authdb->error);
                    return;
                }
                $self->log->info(sprintf("Revoked token: \"%s\"", $payload->{'jti'}));
                $self->reply->json_error(403 => "E1002" => "Access denied. The token has been revoked");
                return;
            }
        }
    } else { # No token specified
        $self->reply->json_error(403 => "E1000" => "Access denied. No token exists");
        return;
    }

    # Set expiration and cachekey to stash if exists
    $self->stash(expiration => $expiration) if $expiration;
    $self->stash(cachekey => $cachekey) if $cachekey;

    # Authorization (username is optional)
    if ($username) {
        my $user = $authdb->authz(
            u => $username,
            's' => 0,
            k => $cachekey,
        );
        unless ($user) {
            $self->log->info(sprintf("Session is not authorized for \"%s\"", $username));
            $self->reply->json_error($authdb->code, $authdb->error || "E1003: Access denied. Session is not authorized");
            return;
        }

        # Stash user data
        $self->stash($user->to_hash);

        # Stah is_authorized flag
        $self->stash(is_authorized => $user->is_authorized ? 1 : 0) ;
    }

    # Access (username is optional; b,m,url,p,i,r will be got from controller)
    my $has_access = $authdb->access(
        c => $self,
        u => $username,
        k => $cachekey,
    );
    unless ($has_access) {
        $self->reply->json_error($authdb->code, $authdb->error || "E1004: Access denied by realm restrictions");
        return;
    }

    # Ok
    return 1;
}
sub authorize {
    my $self = shift;
       $self->timing->begin('suffit_authorize');
    my $token_type = $self->stash('token_type') || '';
    my $skip_authdb_connect = $self->stash('skip_authdb_connect') ? 1 : 0;
    my $username = $self->param('username') // $self->req->json('/username') // '';
    my $password = $self->param('password') // $self->req->json('/password') // '';
    my $encrypted = is_true_flag($self->param('encrypted') // $self->req->json('/encrypted')) || 0;
    my $remember = is_true_flag($self->param('remember') // $self->req->json('/remember')) || 0;
    my $cachekey = $self->param('cachekey') // $self->req->json('/cachekey') // $self->app->gen_cachekey;

    # md5(User-Agent . Remote-Address)
    my $ip = $self->client_ip($self->app->trustedproxies);
    my $clientid = $self->param('clientid') // $self->req->json('/clientid')
        || md5_sum(sprintf("%s%s", $self->req->headers->header('User-Agent') // 'unknown', $ip));

    # Get Referer from flash or header
    my $href = $self->req->headers->header("Referer") // '';
    my $referer = $self->flash("referer") // ($href ? Mojo::URL->new($href)->path->to_string // '' : '');
       $referer =~ s/\/authorize//;
    $self->stash(referer => $referer);

    # Get authdb instance
    my $authdb = $self->authdb;
    return $self->reply->json_error(500 => "E1005" => "The authorization database is not ready") unless $authdb;

    # Connect to AuthDB (optional)
    if (!$skip_authdb_connect) {
        $authdb->connect;
        if ($authdb->error) {
            return $self->reply->json_error(500 => $authdb->error);
        } elsif (!$authdb->initialized) {
            return $self->reply->json_error(500 => "E1307" => "The authorization database is not initialized");
        }
    }

    # Token type
    return $self->reply->json_error(400 => "E1020" => "Incorrect token type. Allowed: session, access, refresh, api")
        unless grep {$token_type eq $_} (qw/session access refresh api/);

    # Please provide username and password for authorization
    return $self->reply->json_error(401 => "E1021" => "No username specified") unless length($username);
    return $self->reply->json_error(401 => "E1022" => "No password specified") unless length($password);

    # Password decrypt
    if ($encrypted && length($password)) {
        my $rsa = WWW::Suffit::RSA->new(private_key => $self->app->private_key);
        $password = $rsa->decrypt($password);
        return $self->reply->json_error(500 => "E1023" => $rsa->error) if $rsa->error; # RSA decrypt error
    }

    # Authentication
    $authdb->authn(
        u => $username,
        p => $password,
        a => $ip, # For check by stats
        k => $cachekey,
    ) or return $self->reply->json_error($authdb->code, $authdb->error); # Unauthenticated (incorrect username or password)

    # Authorization
    my $user = $authdb->authz(
        u => $username,
        's' => 0,
        k => $cachekey,
    );
    return $self->reply->json_error($authdb->code, $authdb->error) unless $user; # Unauthorized (Access denied)

    # Generate token: access, session, api, etc.
    my $jwt = $self->jwt;
    my $jws_algorithm = $authdb->meta("jws_algorithm") || $self->conf->latest("/jws_algorithm") || '';
       $jwt->algorithm($jws_algorithm) if length $jws_algorithm;

    # Expires
    my $now = time(); # NOW
    my $tokenexpires = $authdb->meta("tokenexpires") || parse_time_offset($self->conf->latest("/tokenexpires")) || TOKEN_EXPIRATION;
    my $exp = $now + ($remember ? TOKEN_EXPIRE_MAX : $tokenexpires);
    if ($token_type eq 'api') {
        $exp = $user->forever ? undef : ($now + TOKEN_EXPIRATION * 365);
    }
    my $jti = sprintf("%s%s", randchars(8), $self->req->request_id);
       $jwt->expires($exp);
       $jwt->iat($now)->jti($jti)->payload({
            ver         => $self->app->VERSION,
            typ         => $token_type,
            usr         => $username,
            ip          => $ip,
            cid         => $clientid,
            $cachekey ? (key => $cachekey) : (),
        });

    # Issue (generate)
    my $token = $jwt->encode->token;
    return $self->reply->json_error(500 => "E1024" => $jwt->error || "Can't JWT generate") unless $token; # Can't JWT generation

    # Store token
    $authdb->token_set(
        type        => $token_type,
        jti         => $jti,
        username    => $username,
        clientid    => $clientid,
        iat         => $now,
        exp         => $exp || 0,
        address     => $ip,
    ) or return $self->reply->json_error($authdb->code, $authdb->error || "E1025: Can't token store to database"); # Can't store token data

    # Ok
    return $self->reply->json_ok({
        message     => "The user is successfully authorized",
        encrypted   => $encrypted ? true : false,
        clientid    => $clientid,
        datetime    => Mojo::Date->new($now)->to_datetime, # RFC 3339
        expires     => Mojo::Date->new($exp || 0)->to_datetime, # RFC 3339
        elapsed     => $self->timing->elapsed('suffit_authorize') // 0,
        referer     => $referer,
        jti         => $jti,
        type        => $token_type,
        token       => $token,
        cachekey    => $cachekey,
        user        => { ($user->to_hash(1)) },
    });
}

1;

__END__
