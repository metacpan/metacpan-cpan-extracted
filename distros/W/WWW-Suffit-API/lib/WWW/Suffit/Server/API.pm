package WWW::Suffit::Server::API;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Server::API - The Suffit API controller

=head1 SYNOPSIS

    use WWW::Suffit::Server::API;

=head1 DESCRIPTION

The Suffit API controller

=head1 METHODS

List of internal methods

=head2 api

See L</"GET /api">

=head2 check

See L</"GET /api/check">

=head2 is_connected

This method connects to the authorization database and returns the connection status

    my $r = $app->routes->under('/')
        ->to('API#is_connected')
        ->name('__authdb');

=head1 API METHODS

List of API methods

=head2 GET /api

This method returns general statistics of the API server, available only after authorization

    # curl -v -H "Authorization: Bearer eyJh...s5aM" \
      https://localhost:8695/api

    > GET /api HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...s5aM
    >
    < HTTP/1.1 200 OK
    < Content-Length: 3188
    < Content-Type: application/json;charset=UTF-8
    < Date: Wed, 14 Aug 2024 08:05:01 GMT
    < Server: OWL/1.11
    < Vary: Accept-Encoding
    <
    {
      "algorithms": [ "MD5", "SHA1", "SHA224", "SHA256", "SHA384", "SHA512" ],
      "api_version": "1.02",
      "base_url": "https://localhost:8695",
      "code": "E0000",
      "datetime": "2024-08-14T08:05:01Z",
      "elapsed": 0.000289,
      "entities": {
        "Default": [ "Allow", "Deny" ],
        "Env": [
          "LANG", "LOGNAME", "MOJO_MODE", "USER", "USERNAME",
          "USR1", "USR2", "USR3"
        ],
        "Header": [
          "Accept", "Host", "User-Agent", "X-Token", "X-Auth",
          "X-Usr1", "X-Usr2", "X-Usr3" ],
        "Host": [ "Host", "IP" ],
        "User/Group": [ "User", "Group", "Valid-User" ]
      },
      "files": {
        "datadir": "/tmp/data",
        "documentroot": "/tmp/public",
        "home": "/tmp/www",
        "homedir": "/tmp/www",
        "logfile": null,
        "render_paths": [
          "/tmp/templates", "/tmp/public", "/tmp/www"
        ],
        "static_paths": [ "/tmp/public", "/tmp/www" ],
        "tempdir": "/tmp"
      },
      "generated": 1723622701,
      "is_authorized": true,
      "message": "Ok",
      "methods": [
        "CONNECT", "OPTIONS", "HEAD", "GET", "POST", "PUT",
        "PATCH", "DELETE", "TRACE", "ANY", "MULTI"
      ],
      "namespaces": [
        "WWW::OWL::Server::Controller",
        "WWW::OWL::Server",
        "WWW::Suffit::Server"
      ],
      "operators": [
        { "name": "eq", "operator": "==", "title": "equal to" },
        { "name": "ne", "operator": "!=", "title": "not equal" },
        { "name": "gt", "operator": ">", "title": "greater than" },
        { "name": "lt", "operator": "<", "title": "less than" },
        { "name": "ge", "operator": ">=", "title": "greater than or equal to" },
        { "name": "le", "operator": "<=", "title": "less than or equal to" },
        { "name": "re", "operator": "=~", "title": "regexp match" },
        { "name": "rn", "operator": "!~", "title": "regexp not match" }
      ],
      "project": "XXX",
      "providers": [ "Default", "User/Group", "Host", "Env", "Header" ],
      "public_key": "-----BEGIN RSA PUBLIC KEY-----...",
      "remote_addr": "127.0.0.1",
      "requestid": "MsojYEwbL8Nx",
      "route": "api-data",
      "status": true,
      "token": "eyJh...BQIM",
      "trustedproxies": [ "127.0.0.1", "10.0.0.0/8" ],
      "user": {
        "attributes": "",
        "cachekey": null,
        "comment": "Test user for internal testing only",
        "email": "test@owl.localhost",
        "email_md5": "163e50783979333ebae6fd63b2d96d16",
        "expiration": 1723708629,
        "expires": 1723622701,
        "flags": 31,
        "groups": [ "user" ],
        "name": "Test User",
        "public_key": "-----BEGIN RSA PUBLIC KEY-----...",
        "role": "Test user",
        "username": "test"
      },
      "version": "1.11",
      "year": "2024"
    }

=head2 GET /api/check

This method simply checks the readiness state of the Suffit API server to interaction

B<NOTE!> The method does not require authorization

    # curl -v https://localhost:8695/api/check

    > GET /api/check HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    >
    < HTTP/1.1 200 OK
    < Content-Length: 241
    < Content-Type: application/json;charset=UTF-8
    < Date: Wed, 14 Aug 2024 07:31:08 GMT
    < Server: OWL/1.11
    <
    {
      "api_version": "1.02",
      "base_url": "https://localhost:8695",
      "code": "E0000",
      "datetime": "2024-08-14T07:31:08Z",
      "message": "Ok",
      "project": "OWL",
      "remote_addr": "127.0.0.1",
      "requestid": "l6TPHQ2TX4vl",
      "status": true,
      "time": 1723620668,
      "version": "1.11"
    }

=head2 GET /api/status

This method returns extended status information about the Suffit API server state

B<NOTE!> The method does not require authorization

    # curl -v https://localhost:8695/api/status

    > GET /api/status HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    >
    < HTTP/1.1 200 OK
    < Content-Length: 606
    < Content-Type: application/json;charset=UTF-8
    < Date: Wed, 14 Aug 2024 07:44:31 GMT
    < Server: OWL/1.11
    <
    {
      "api_version": "1.02",
      "base_url": "https://localhost:8695",
      "code": "E0000",
      "datetime": "2024-08-14T07:44:31Z",
      "elapsed": 0.00079,
      "generated": 1723621471,
      "is_authorized": false,
      "message": "Ok",
      "project": "OWL",
      "public_key": "-----BEGIN RSA PUBLIC KEY-----...",
      "remote_addr": "127.0.0.1",
      "requestid": "6vJjylIPm0mY",
      "route": "api-status",
      "status": true,
      "token": "",
      "version": "1.11",
      "year": "2024"
    }

=head1 ERROR CODES

The list of public Suffit API error codes

    API   | HTTP  | DESCRIPTION
   -------+-------+-------------------------------------------------
    E1030   [---]   Reserved
    ...
    E1059   [---]   Reserved

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

Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Mojo::Base 'Mojolicious::Controller';

use POSIX qw/ strftime /;

use Mojo::JSON qw/ true false /;
use Mojo::Date;

use WWW::Suffit::API;
use WWW::Suffit::Const qw/ :dicts DIGEST_ALGORITHMS /;

sub is_connected {
    my $self = shift; # Controller

    # Get authdb instance
    my $authdb = $self->authdb;
    unless ($authdb) {
        $self->reply->json_error(500 => "E1005" => "The authorization database is not ready");
        return;
    }

    # Connect to AuthDB
    $authdb->connect;
    if ($authdb->error) {
        $self->reply->json_error($authdb->code, $authdb->error);
        return;
    } elsif (!$authdb->initialized) {
        $self->reply->json_error(500 => "E1307" => "The authorization database is not initialized");
        return;
    }

    # Ok
    return 1;
}
sub api {
    my $self = shift;
    $self->timing->begin('suffit_api'); # stuff
    my $now = time;
    my $status = 1;
    my $code = "E0000";
    my $message = "Ok";
    my $username = $self->stash('username'); # from Auth::is_authorized
    my $cachekey = $self->stash('cachekey'); # from Auth::is_authorized

    # Extended data of user
    my $is_authorized = 0;
    my $user = undef;
    if ($username) {
        $user = $self->authdb->user($username, $cachekey);
        return $self->reply->json_error($self->authdb->code, $self->authdb->error) if $self->authdb->error;
        $is_authorized = $user->is_authorized;
    }

    return $self->render(json => {
            status          => $status ? true : false,
            code            => $code,
            message         => $message,
            project         => $self->app->project_name,
            version         => $self->app->project_version,
            api_version     => WWW::Suffit::API->VERSION,
            generated       => $now,
            datetime        => Mojo::Date->new($now)->to_datetime, # RFC 3339
            requestid       => $self->req->request_id,
            remote_addr     => $self->remote_ip($self->app->trustedproxies),
            base_url        => $self->base_url,
            token           => $self->token,
            public_key      => $self->app->public_key,
            year            => strftime('%Y', localtime $now),
            route           => $self->current_route // 'root',
            elapsed         => $self->timing->elapsed('suffit_api') // 0,
            is_authorized   => $is_authorized ? true : false,

            # Authorized only
            $is_authorized ? (
                algorithms      => DIGEST_ALGORITHMS,
                methods         => HTTP_METHODS,
                providers       => AUTHZ_PROVIDERS,
                entities        => AUTHZ_ENTITIES,
                operators       => AUTHZ_OPERATOTS,
                trustedproxies  => $self->app->trustedproxies,
                namespaces      => $self->app->routes->namespaces,

                # User information
                user => {
                    username    => $username,
                    cachekey    => $cachekey,
                    name        => $self->stash('name'),
                    email       => $self->stash('email'),
                    email_md5   => $self->stash('email_md5'),
                    role        => $self->stash('role'),
                    groups      => $self->stash('groups'),
                    expiration  => $self->stash('expiration'), # Session expiration time (no user data!)
                    expires     => $self->stash('expires'), # Cache expiration time
                    # Extended fields
                    attributes  => $user->attributes // '',
                    flags       => $user->flags || 0,
                    public_key  => $user->public_key // '',
                    comment     => $user->comment // '',
                },

                # Fies & Directories
                files => {
                    home        => $self->app->home->to_string,
                    homedir     => $self->app->homedir,
                    datadir     => $self->app->datadir,
                    documentroot=> $self->app->documentroot,
                    tempdir     => $self->app->tempdir,
                    logfile     => $self->app->logfile,
                    static_paths=> $self->app->static->paths,
                    render_paths=> $self->app->renderer->paths,
                },
            ) : (),
        });
}
sub check {
    my $self = shift;
    my $now = time;
    return $self->reply->json_ok({
        message         => "Ok",
        project         => $self->app->project_name,
        version         => $self->app->project_version,
        api_version     => WWW::Suffit::API->VERSION,
        time            => $now,
        datetime        => Mojo::Date->new($now)->to_datetime, # RFC 3339
        requestid       => $self->req->request_id,
        remote_addr     => $self->remote_ip($self->app->trustedproxies),
        base_url        => $self->base_url,
    });
}

1;

__END__
