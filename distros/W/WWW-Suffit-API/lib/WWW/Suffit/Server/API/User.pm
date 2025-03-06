package WWW::Suffit::Server::API::User;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Server::API::User - The Suffit API controller for user management

=head1 SYNOPSIS

    use WWW::Suffit::Server::API::User;

=head1 DESCRIPTION

The Suffit API controller for user management

This module uses the following configuration directives:

=over 8

=item JWS_Algorithm

Allowed JWS signing algorithms: B<HS256>, B<HS384>, B<HS512>, B<RS256>, B<RS384>, B<RS512>

    HS256   HMAC+SHA256 integrity
    HS384   HMAC+SHA384 integrity
    HS512   HMAC+SHA512 integrity
    RS256   RSA+PKCS1-V1_5 + SHA256 signature
    RS384   RSA+PKCS1-V1_5 + SHA384 signature
    RS512   RSA+PKCS1-V1_5 + SHA512 signature

Default: B<HS256>

=back

=head1 METHODS

List of internal methods

=head2 genkeys

See L</"POST /api/user/genkeys">

=head2 passwd

See L</"PATCH /api/user/passwd">

=head2 token_del

See L</"DELETE /api/user/token/JTI">

=head2 token_get

See L</"GET /api/user/token">

=head2 token_set

See L</"POST /api/user/token">

=head2 user_get

See L</"GET /api/user">

=head2 user_set

See L</"PUT /api/user">

=head1 API METHODS

List of API methods

=head2 GET /api/user

This method returns user data

    # curl -v -H "Authorization: Bearer eyJh...s5aM" \
      https://localhost:8695/api/user

    > GET /api/user HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...s5aM
    >
    < HTTP/1.1 200 OK
    < Content-Length: 653
    < Content-Type: application/json;charset=UTF-8
    < Date: Wed, 14 Aug 2024 16:33:34 GMT
    < Server: OWL/1.11
    <
    {
      "algorithm": "SHA256",
      "attributes": "",
      "code": "E0000",
      "comment": "Test user for internal testing only",
      "created": 1678741533,
      "email": "test@owl.localhost",
      "email_md5": "163e50783979333ebae6fd63b2d96d16",
      "expires": 0,
      "flags": 31,
      "groups": [
        "user"
      ],
      "name": "Test User",
      "not_after": 0,
      "not_before": 1695334721,
      "public_key": "-----BEGIN RSA PUBLIC KEY-----...",
      "role": "Test user",
      "status": true,
      "uid": 3,
      "username": "test"
    }

=head2 PUT /api/user

Edit user's data

    # curl -v -H "Authorization: OWL eyJh...04qI" \
      -X PUT -d '{
        "name": "Test User",
        "email": "test@owl.localhost",
        "role": "Test user",
        "comment": "Test user for internal testing only"
      }' \
      https://owl.localhost:8695/api/user

    > PUT /api/user HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...04qI
    > Content-Length: 163
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 200 OK
    < Content-Length: 148
    < Server: OWL/1.00
    < Date: Mon, 15 May 2023 11:25:11 GMT
    < Content-Type: application/json;charset=UTF-8
    <
    {
      "comment": "Test user for internal testing only",
      "email": "test@owl.localhost",
      "name": "Test User",
      "role": "Test user",
      "status": true,
      "username": "test"
    }

=head2 POST /api/user/genkeys

Issue (generation) RSA keys pair (public and private RSA keys) for user

    # curl -v -X POST -H "Authorization: OWL eyJh...R_0c" \
      https://owl.localhost:8695/api/user/genkeys

    > POST /api/user/genkeys HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...R_0c
    >
    < HTTP/1.1 200 OK
    < Date: Fri, 12 May 2023 06:31:21 GMT
    < Server: OWL/1.00
    < Content-Type: application/json;charset=UTF-8
    < Content-Length: 1228
    <
    {
      "error": "",
      "private_key": "-----BEGIN RSA PRIVATE KEY-----...",
      "public_key": "-----BEGIN RSA PUBLIC KEY-----",
      "status": true
    }

=head2 PATCH /api/user/passwd

Change password for user

    # curl -v -H "Authorization: OWL eyJh...Bh7g" \
      -X PATCH -d '{
        "current": "currentPassword",
        "password": "newPassword"
      }' \
      https://owl.localhost:8695/api/user/passwd

    > PATCH /api/user/passwd HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...04qI
    > Content-Length: 64
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 200 OK
    < Server: OWL/1.00
    < Content-Type: application/json;charset=UTF-8
    < Content-Length: 30
    < Date: Mon, 15 May 2023 11:36:50 GMT
    <
    {
      "code": "E0000",
      "status": true
    }

=head2 DELETE /api/user/token/JTI

Removes specified token from list of tokens for user of current session

    # curl -v -X DELETE -H "Authorization: OWL eyJh...04qI" \
      https://owl.localhost:8695/api/user/token/SqpHCfCS2646efd7

    > DELETE /api/user/token/SqpHCfCS2646efd7 HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...04qI
    >
    < HTTP/1.1 200 OK
    < Server: OWL/1.00
    < Content-Type: application/json;charset=UTF-8
    < Content-Length: 30
    < Date: Mon, 15 May 2023 11:11:35 GMT
    <
    {
      "code": "E0000",
      "status": true
    }

=head2 GET /api/user/token

Get list of tokens for user of current session

    # curl -v -X GET -H "Authorization: OWL eyJh...04qI" \
      https://owl.localhost:8695/api/user/token

    > GET /api/user/token HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...04qI
    >
    < HTTP/1.1 200 OK
    < Server: OWL/1.00
    < Date: Mon, 15 May 2023 11:02:33 GMT
    < Content-Length: 491
    < Content-Type: application/json;charset=UTF-8
    <
    [
      {
        "address": "127.0.0.1",
        "clientid": "b048c047a0f0165ab7630f7aab1cb5aa",
        "exp": 1684227656,
        "iat": 1684141256,
        "id": 88,
        "jti": "ke2uj4ib059db017",
        "type": "session",
        "username": "test",
        "description": ""
      }
    ]

=head2 POST /api/user/token

Issues the new API token for user of current session by session or access token

    # curl -v -X POST -H "Authorization: OWL eyJh...aMTc" \
      https://owl.localhost:8695/api/user/token

    > POST /api/user/token HTTP/1.1
    > Host: owl.localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: OWL eyJh...aMTc
    >
    < HTTP/1.1 200 OK
    < Server: OWL/1.00
    < Content-Type: application/json;charset=UTF-8
    < Content-Length: 586
    < Date: Fri, 12 May 2023 05:42:37 GMT
    <
    {
      "address": "127.0.0.1",
      "clientid": "f459f12619c961122450ae5883e44a60",
      "exp": 0,
      "iat": 1683870157,
      "id": 87,
      "jti": "SqpHCfCS2646efd7",
      "status": true,
      "token": "eyJh...H8ac",
      "type": "api",
      "username": "test",
      "description": ""
    }

=head1 ERROR CODES

The list of User Suffit API error codes

    API   | HTTP  | DESCRIPTION
   -------+-------+-------------------------------------------------
    E1120   [400]   Incorrect username
    E1121   [400]   Incorrect current password
    E1122   [400]   Incorrect new password
    E1123   [500]   Can't generate RSA keys
    E1124   [500]   Can't JWT generate
    E1125   [500]   Can't token store to database
    E1126   [400]   Incorrect JWT jti
    E1127   [500]   Can't delete token from database
    E1128   [500]   Can't edit user data (user_set)
    E1129   [500]   Can't change user password
    E1130   [500]   Can't save RSA keys to database

B<*> -- this code will be defined later on the interface side

See also list of common Suffit API error codes in L<WWW::Suffit::API/"ERROR CODES">

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Mojolicious>, L<WWW::Suffit>, L<WWW::Suffit::Server>, L<WWW::Suffit::API>

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

use Mojo::Util qw/ trim /;

use Acrux::Util qw/ randchars /;

use WWW::Suffit::Const qw/ USERNAME_REGEXP TOKEN_EXPIRATION JTI_REGEXP /;

sub user_get {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # Get username from session
    my $username = $self->stash('username') // ''; # from Auth::is_authorized
    return $self->reply->json_error(400 => "E1120" => "Incorrect username")
        unless length($username) && (length($username) <= 64) && $username =~ USERNAME_REGEXP;

    # Get user instance
    my $user = $authdb->user($username);
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;

    # Ok
    return $self->reply->json_ok({($user->to_hash(1))});
}
sub user_set {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # Get username from session
    my $username = $self->stash('username') // ''; # from Auth::is_authorized
    return $self->reply->json_error(400 => "E1120" => "Incorrect username")
        unless length($username) && (length($username) <= 64) && $username =~ USERNAME_REGEXP;

    # Get user instance
    my $user = $authdb->user($username);
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;

    # Get user data from input json
    my %data = (
        username=> $username,
        comment => $self->req->json('/comment') // '',
        email   => $self->req->json('/email') // '',
        name    => $self->req->json('/name') // '',
        role    => $self->req->json('/role') // '',
    );

    # User edit
    $authdb->user_edit(%data)
        or return $self->reply->json_error($authdb->code, $authdb->error || "E1128: Can't edit user data");

    # Render ok
    return $self->reply->json_ok({ %data });
}
sub passwd {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # Get username from session
    my $username = $self->stash('username') // ''; # from Auth::is_authorized
    return $self->reply->json_error(400 => "E1120" => "Incorrect username")
        unless length($username) && (length($username) <= 64) && $username =~ USERNAME_REGEXP;

    # Get data from input json
    my $cur = trim($self->req->json('/current') // '');
    my $pwd = trim($self->req->json('/password') // '');
    return $self->reply->json_error(400 => "E1121" => "Incorrect current password")
        unless length($cur) && (length($cur) <= 255);
    return $self->reply->json_error(400 => "E1122" => "Incorrect new password")
        unless length($pwd) && (length($pwd) <= 255);

    # Authentication with old password
    $authdb->authn(
        u => $username,
        p => $cur,
        a => $self->client_ip($self->app->trustedproxies),
        k => $self->stash('cachekey'),
    ) or return $self->reply->json_error(400 => $authdb->error || "E1121: Incorrect current password");

    # Store data
    $authdb->user_passwd(username => $username, password => $pwd)
        or return $self->reply->json_error($authdb->code, $authdb->error || "E1129: Can't change user password");

    # Render ok
    return $self->reply->json_ok;
}
sub genkeys {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # Get username from session
    my $username = $self->stash('username') // ''; # from Auth::is_authorized
    return $self->reply->json_error(400 => "E1120" => "Incorrect username")
        unless length($username) && (length($username) <= 64) && $username =~ USERNAME_REGEXP;

    # Gen RSA keys
    my %rsadata = $self->gen_rsakeys;
    return $self->reply->json_error(500 => "E1123" => $rsadata{error}) if $rsadata{error};
    $self->log->info(sprintf("Generate new %s bit RSA key pair for user %s", $rsadata{key_size}, $username));

    # Store data
    $authdb->user_setkeys(%rsadata, username => $username)
        or return $self->reply->json_error($authdb->code, $authdb->error || "E1130: Can't save RSA keys to database");

    # Render ok
    return $self->reply->json_ok({ %rsadata });
}
sub token_get {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # Get username from session
    my $username = $self->stash('username') // ''; # from Auth::is_authorized
    return $self->reply->json_error(400 => "E1120" => "Incorrect username")
        unless length($username) && (length($username) <= 64) && $username =~ USERNAME_REGEXP;

    # Get tokens
    my @tokens = $authdb->user_tokens($username);
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;

    # Render
    return $self->render(json => [@tokens]);
}
sub token_set {
    my $self = shift;
    my $authdb = $self->authdb->clean;
    my $clientid = $self->req->json('/clientid') || $self->clientid;
    my $cachekey = $self->req->json('/cachekey') // $self->app->gen_cachekey;
    my $description = $self->req->json('/description') // '';

    # Get username from session
    my $username = $self->stash('username') // ''; # from Auth::is_authorized
    return $self->reply->json_error(400 => "E1120" => "Incorrect username")
        unless length($username) && (length($username) <= 64) && $username =~ USERNAME_REGEXP;

    # Get user instance
    my $user = $authdb->user($username);
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;

    # Generate API token
    my $jwt = $self->jwt;
    my $now = time;
    my $exp = $user->forever ? undef : ($now + TOKEN_EXPIRATION * 365);
    my $jti = sprintf("%s%s", randchars(8), $self->req->request_id);
       $jwt->algorithm($self->conf->latest("/jws_algorithm")) if $self->conf->latest("/jws_algorithm");
       $jwt->expires($exp); # Set or Flush expires
       $jwt->iat($now)->jti($jti)->payload({
            ver         => $self->app->VERSION,
            typ         => 'api',
            usr         => $username,
            ip          => $self->remote_ip($self->app->trustedproxies),
            cid         => $clientid,
            $cachekey ? (key => $cachekey) : (),
        });
    my $token = $jwt->encode->token;
    return $self->reply->json_error(500 => $jwt->error || "E1124: Can't JWT generate") unless $token;

    # Store
    $authdb->token_set(
        type        => 'api',
        jti         => $jti,
        username    => $username,
        clientid    => $clientid,
        iat         => $now,
        exp         => $exp || 0,
        address     => $self->remote_ip($self->app->trustedproxies),
        description => $description,
    ) or return $self->reply->json_error($authdb->code, $authdb->error || "E1125: Can't token store to database");

    # Get actual data by username and jti
    my %issued = $authdb->token_get($username, $jti);
    return $self->reply->json_error($authdb->code, $authdb->error) if $authdb->error;
    $issued{token} = $token;

    # Render ok
    return $self->reply->json_ok({ %issued });
}
sub token_del {
    my $self = shift;
    my $authdb = $self->authdb->clean;

    # Get username from session
    my $username = $self->stash('username') // ''; # from Auth::is_authorized
    return $self->reply->json_error(400 => "E1120" => "Incorrect username")
        unless length($username) && (length($username) <= 64) && $username =~ USERNAME_REGEXP;

    # Get jti from URL path
    my $jti = trim($self->param('jti') // '');
    return $self->reply->json_error(400 => "E1126" => "Incorrect JWT jti")
        unless length($jti) && (length($jti) <= 64) && $jti =~ JTI_REGEXP;

    # Delete from database
    $authdb->token_del($username, $jti)
        or return $self->reply->json_error($authdb->code, $authdb->error || "E1127: Can't delete token from database");

    # Render ok
    return $self->reply->json_ok;
}

1;

__END__
