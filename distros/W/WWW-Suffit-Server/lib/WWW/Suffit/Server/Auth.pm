package WWW::Suffit::Server::Auth;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Server::Auth - The authentication and authorization Suffit API controller

=head1 SYNOPSIS

    use WWW::Suffit::Server::Auth;

=head1 DESCRIPTION

The authentication and authorization Suffit API controller

=head1 METHODS

List of authorization/authentication methods

=head2 authorize

    $c->routes->post('/authorize')->to('auth#authorize'
      => {token_type => 'session'});
    $c->routes->post('/authorize')->to('auth#authorize'
      => {token_type => 'access'});
    $c->routes->post('/authorize')->to('auth#authorize'
      => {token_type => 'api'});

The authorization controller  by stashed parameters

See L<WWW::Suffit::API/"POST /authorize">

=head2 is_authorized

    my $authorized = $c->routes->under('/api')->to('auth#is_authorized')
         ->name('api');

The API Authorization checker. If use `init_api_routes` startup option then
this route will be exists by default. To get access to this route use:

    my $authorized = $r->lookup('api');

=head2 is_authorized_api

See L</is_authorized>

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<WWW::Suffit::Server>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.01';

use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON qw / true false /;
use Mojo::Util qw/ md5_sum /;
use Mojo::Date;
use Mojo::URL;
use Mojo::JSON qw / true false /;

use WWW::Suffit::Const qw/ TOKEN_EXPIRATION TOKEN_EXPIRE_MAX /;
use WWW::Suffit::Util qw/ parse_time_offset randchars /;
use WWW::Suffit::RSA;

sub is_authorized {
    my $self = shift;
    my ($username, $expiration);
    $self->authdb->username(""); # Flash username first!

    # The authorization database not inialized
    unless ($self->authdb->meta("meta.inited")) {
        $self->reply->json_error($self->authdb->error || "E1005: The authorization database is not initialized. Please run \"owl-cli authdb import\" first");
        return;
    }

    # Get authorization data from token (if specified)
    if (my $token = $self->token) {
        my $jwt = $self->jwt;

        # Get payload from JWT
        my $payload = $jwt->decode($token)->payload;
        if ($jwt->error) {
            $self->log->error(sprintf("E1001: Access denied. %s", $jwt->error));
            $self->render(json => {
                status  => false,
                code    => "E1001",
                message => sprintf("Access denied. %s", $jwt->error),
            }, status => 403);
            return;
        }
        $username = $payload->{'usr'};
        $expiration = $payload->{'exp'} || (time + TOKEN_EXPIRATION);

        # Check the token by database
        if ($payload->{'jti'}) {
            unless ($self->authdb->token_check($username, $payload->{'jti'})) {
                if ($self->authdb->error) {
                    $self->log->error($self->authdb->error);
                    $self->render(json => {
                        status  => false,
                        code    => "E0500",
                        message => $self->authdb->error,
                    }, status => 500);
                    return;
                }
                $self->log->error(sprintf("E1002: Access denied. The token %s has been revoked", $payload->{'jti'}));
                $self->render(json => {
                    status  => false,
                    code    => "E1002",
                    message => sprintf("Access denied. The token %s has been revoked", $payload->{'jti'}),
                }, status => 403);
                return;
            }
        }
    } else { # No token specified
        $self->log->error("E1000: Access denied. No token exists");
        $self->render(json => {
            status  => false,
            code    => "E1000",
            message => "E1000: Access denied. No token exists",
        }, status => 403);
        return;
    }

    # Set expiration stash if exists
    $self->stash(expiration => $expiration) if $expiration;

    # Authorization (username is optional)
    if ($username) {
        my $user = $self->authdb->username($username)->authz($username);
        unless ($user) {
            $self->log->error($self->authdb->error || "E1003: Access denied. Session is not authorized for $username");
            $self->render(json => {
                status  => false,
                code    => "E1003",
                message => $self->authdb->error || "Access denied. Session is not authorized",
            }, status => $self->authdb->code);
            return;
        }

        # Stash user data
        $self->stash($user->to_hash);
    }

    # Access (username is optional)
    unless ($self->authdb->access(controller => $self, username => $username)) {
        $self->log->error($self->authdb->error || "E1004: Access denied by realm restrictions");
        $self->render(json => {
            status  => false,
            code    => "E1004",
            message => $self->authdb->error || "Access denied by realm restrictions",
        }, status => $self->authdb->code);
        return;
    }

    # Ok
    return 1;
}
sub is_authorized_api { goto &is_authorized }
sub authorize {
    my $self = shift;
       $self->timing->begin('suffit_authorize');
    my $token_type = $self->stash('token_type') || '';
    my $username = $self->param('username') // $self->req->json('/username') // '';
    my $password = $self->param('password') // $self->req->json('/password') // '';
    my $encrypted = $self->param('encrypted') // $self->req->json('/encrypted') || 0;
    my $remember = $self->param('remember') // $self->req->json('/remember') || 0;;

    # md5(User-Agent . Remote-Address)
    my $ip = $self->client_ip($self->app->trustedproxies);
    my $clientid = $self->param('clientid') // $self->req->json('/clientid')
        || md5_sum(sprintf("%s%s", $self->req->headers->header('User-Agent') // 'unknown', $ip));

    # Get Referer from flash or header
    my $href = $self->req->headers->header("Referer") // '';
    my $referer = $self->flash("referer") // ($href ? Mojo::URL->new($href)->path->to_string // '' : '');
       $referer =~ s/\/authorize//;
    $self->stash(referer => $referer);

    # Token type
    return $self->reply->json_error(400 => "E0400" => "Incorrect token type. Supported types: session, access, api")
        unless grep {$token_type eq $_} (qw/session access api/);

    # AuthDB
    my $authdb = $self->authdb->clean;

    # Please provide username and password for authorization
    return $self->reply->json_error(401 => "E0401" => "No username specified") unless length($username);
    return $self->reply->json_error(401 => "E0401" => "No password specified") unless length($password);

    # Password decrypt
    if ($encrypted && length($password)) {
        my $rsa = WWW::Suffit::RSA->new(private_key => $self->app->private_key);
        $password = $rsa->decrypt($password);
        return $self->reply->json_error(500 => "E1064" => $rsa->error) if $rsa->error; # RSA decrypt error
    }

    # Authentication
    $authdb->username($username);
    $authdb->address($ip); # For check by stats
    unless ($authdb->authen($username, $password)) { # Unauthenticated
        return $self->reply->json_error($authdb->code, "E1060", $authdb->error || "Incorrect username or password");
    }

    # Authorization
    my $user = $authdb->authz($username);
    return $self->reply->json_error($authdb->code, "E1061", $authdb->error || "Access denied") unless $user; # Unauthorized

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
        });

    # Issue (generate)
    my $token = $jwt->encode->token;
    return $self->reply->json_error(500 => "E1062" => $jwt->error || "Can't JWT generate") unless $token; # Can't JWT generation

    # Store token
    unless ($authdb->token_set(
        type        => $token_type,
        jti         => $jti,
        username    => $username,
        clientid    => $clientid,
        iat         => $now,
        exp         => $exp || 0,
        address     => $ip,
    )) {
        # Can't store token data
        return $self->reply->json_error(500 => "E1063" => $authdb->error || "Can't token store to database");
    }

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
        user        => { ($user->to_hash(1)) },
    });
}

1;

__END__
