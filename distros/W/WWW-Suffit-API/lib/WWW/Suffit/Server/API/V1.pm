package WWW::Suffit::Server::API::V1;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Server::API::V1 - The public Suffit API controller, version 1

=head1 SYNOPSIS

    use WWW::Suffit::Server::API::V1;

=head1 DESCRIPTION

The public Suffit API controller, version 1

=head1 METHODS

List of internal methods

=head2 authn

See L</"POST /api/v1/authn">

=head2 authz

See L</"POST /api/v1/authz">

=head2 public_key

See L</"GET /api/v1/publicKey">

=head1 API METHODS

List of API methods

=head2 POST /api/v1/authn

This method performs authentication of the remote user

    # curl -v -H "Authorization: Bearer eyJh...Ggns" \
      -X POST -d '{
        "username": "bob",
        "password": "bob",
        "address": "1.2.3.4",
        "encrypted": false
      }' \
      https://localhost:8695/api/v1/authn

    > POST /api/v1/authn HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...Ggns
    > Content-Length: 120
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 200 OK
    < Content-Length: 30
    < Content-Type: application/json;charset=UTF-8
    < Date: Wed, 14 Aug 2024 10:18:22 GMT
    < Server: OWL/1.11
    <
    {
      "code": "E0000",
      "status": true
    }

    # curl -v -H "Authorization: Bearer eyJh...Ggns" \
      -X POST -d '{
        "username": "bob",
        "password": "incorrect",
        "address": "1.2.3.4",
        "encrypted": false
      }' \
      https://localhost:8695/api/v1/authn

    > POST /api/v1/authn HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...Ggns
    > Content-Length: 126
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 401 Unauthorized
    < Content-Length: 74
    < Content-Type: application/json;charset=UTF-8
    < Date: Wed, 14 Aug 2024 10:22:11 GMT
    < Server: OWL/1.11
    <
    {
      "code": "E1326",
      "message": "Incorrect username or password",
      "status": false
    }

=head2 POST /api/v1/authz

This method performs authorization and checks access grants of the remote user

    # curl -v -H "Authorization: Bearer eyJh...Ggns" \
      -X POST -d '{
        "username": "bob",
        "method": "GET",
        "url": "https://owl.localhost:8695/stuff",
        "address": "1.2.3.4",
        "headers": {
            "Accept": "text/html,text/plain",
            "Connection": "keep-alive",
            "Host": "localhost:8695"
        }
      }' \
      https://localhost:8695/api/v1/authz

    > POST /api/v1/authz HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...Ggns
    > Content-Length: 296
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 200 OK
    < Content-Length: 30
    < Content-Type: application/json;charset=UTF-8
    < Date: Wed, 14 Aug 2024 10:40:17 GMT
    < Server: OWL/1.11
    <
    {
      "code": "E0000",
      "status": true
    }

    # curl -v -H "Authorization: Bearer eyJh...Ggns" \
      -X POST -d '{
        "username": "bob",
        "method": "GET",
        "url": "https://localhost:8695/api/check",
        "address": "1.2.3.4",
        "verbose": true
      }' \
      https://localhost:8695/api/v1/authz

    > POST /api/v1/authz HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...Ggns
    > Content-Length: 166
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 200 OK
    < Content-Length: 289
    < Content-Type: application/json;charset=UTF-8
    < Date: Wed, 14 Aug 2024 10:56:45 GMT
    < Server: OWL/1.11
    <
    {
      "address": "1.2.3.4",
      "base": "https://localhost:8695",
      "code": "E0000",
      "email": "bob@example.com",
      "email_md5": "4b9bb80620f03eb3719e0a061c14283d",
      "expires": 1723633005,
      "groups": [],
      "method": "GET",
      "name": "Bob Bob",
      "path": "/api/check",
      "role": "Test user",
      "status": true,
      "uid": 13,
      "username": "bob"
    }

    # curl -v -H "Authorization: Bearer eyJh...Ggns" \
      -X POST -d '{
        "username": "unknown",
        "method": "GET",
        "url": "https://localhost:8695/api/check",
        "address": "1.2.3.4"
      }' \
      https://localhost:8695/api/v1/authz

    > POST /api/v1/authz HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...Ggns
    > Content-Length: 145
    > Content-Type: application/x-www-form-urlencoded
    >
    < HTTP/1.1 401 Unauthorized
    < Content-Length: 58
    < Content-Type: application/json;charset=UTF-8
    < Date: Wed, 14 Aug 2024 10:43:43 GMT
    < Server: OWL/1.11
    <
    {
      "code": "E1310",
      "message": "User not found",
      "status": false
    }

=head2 GET /api/v1/publicKey

Get RSA public key of user (of the token issuer)

    # curl -v -H "Authorization: Bearer eyJh...Ggns" \
      https://localhost:8695/api/v1/publicKey

    > GET /api/v1/publicKey HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...Ggns
    >
    < HTTP/1.1 200 OK
    < Content-Length: 306
    < Content-Type: application/json;charset=UTF-8
    < Date: Wed, 14 Aug 2024 11:02:33 GMT
    < Server: OWL/1.11
    <
    {
      "code": "E0000",
      "public_key": "-----BEGIN RSA PUBLIC KEY-----...",
      "status": true
    }

=head1 ERROR CODES

List of V1 Suffit API error codes

    API   | HTTP  | DESCRIPTION
   -------+-------+-------------------------------------------------
    E1100   [404]   No RSA public key found
    E1101   [400]   No RSA private key found
    E1102   [500]   RSA decrypt error
    E1103   [ * ]   Incorrect username or password
    E1104   [ * ]   Access denied (authz)
    E1105   [ * ]   Access denied by realm restrictions (access)
    E1106   [---]   Reserved
    E1107   [---]   Reserved
    E1108   [---]   Reserved
    E1109   [---]   Reserved

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

use Mojo::Path;
use Mojo::URL;

use Acrux::RefUtil qw/ is_hash_ref /;

use WWW::Suffit::RSA;

sub authn {
    my $self = shift;
    my $username = $self->req->json('/username') // '';
    my $password = $self->req->json('/password') // '';
    my $address = $self->req->json('/address') // '';
    my $encrypted = $self->req->json('/encrypted') || 0;
    my $cachekey = $self->stash('cachekey');
    my $authdb = $self->authdb;
    my $acc_user = $authdb->cached_user($self->stash('username'), $cachekey);
    my $public_key = $acc_user->public_key // '';
    my $private_key = $acc_user->private_key // '';
    $authdb->clean;

    # Password decrypt
    if ($encrypted && length($password)) {
        return $self->reply->json_error(400 => "E1100" => "No RSA public key found") unless length $public_key;
        return $self->reply->json_error(400 => "E1101" => "No RSA private key found") unless length $private_key;
        my $rsa = WWW::Suffit::RSA->new->private_key($private_key);
        $password = $rsa->decrypt($password); # RSA Decrypt password
        return $self->reply->json_error(500 => "E1102" => $rsa->error || "RSA decrypt error") if $rsa->error;
    }

    # Authentication
    return $self->reply->json_error(
        $authdb->code, $authdb->error || "E1103: Incorrect username or password"
    ) unless $authdb->authn(
        u => $username,
        p => $password,
        k => $cachekey,
        a => $address, # For check by stats
    ); # Unauthenticated

    # Render ok
    return $self->reply->json_ok;
}
sub authz {
    my $self = shift;
    my $authdb = $self->authdb->clean;
    my $cachekey = $self->stash('cachekey');
    my $username = $self->req->json('/username') // '';
    my $verbose = $self->req->json('/verbose') || 0;
    my $url = $self->req->json('/url') // $self->base_url // '';
    my $uri = Mojo::URL->new($url);
       $username = $uri->username unless length $username;
    my %args = (controller => $self, username => $username, cachekey => $cachekey);
    $args{address} = $self->req->json('/address') // '';
    $args{method} = $self->req->json('/method') // '';
    $args{path} = $self->req->json('/path') //
        $uri->path->leading_slash(1)->trailing_slash(0)->to_string // '';
    $args{base} = $self->req->json('/base') //
        $uri->path_query("")->path(Mojo::Path->new->leading_slash(0)->trailing_slash(0) )->to_string // '';
    my $headers = $self->req->json('/headers') || {};
    if (is_hash_ref($headers)) {
        my %hdrs = ();
        while (my ($k, $v) = each %$headers) {
            $hdrs{$k} = $v if defined($v) && !ref($v);
        }
        $args{headers} = {%hdrs} if scalar %hdrs;
    }

    # Authorization (External!)
    my $user = $authdb->authz(
        u => $username,
        's' => 1,
        k => $cachekey,
    );
    return $self->reply->json_error(
        $authdb->code, $authdb->error || "E1104: Access denied"
    ) unless $user; # Unauthorized
    #$self->log->debug($self->dumper($user));

    # Access (username is optional)
    return $self->reply->json_error(
        $authdb->code, $authdb->error || "E1105: Access denied by realm restrictions"
    ) unless ($authdb->access(%args)); # Forbidden

    # Render ok
    return $self->reply->json_ok unless $verbose;

    # Render user data
    my %ret = $user->to_hash;
    $ret{address} = $args{address} if length $args{address};
    foreach my $k (qw/method path base/) {
        $ret{$k} = $args{$k} if length $args{$k};
    }
    $ret{headers} = $args{headers} if exists $args{headers};

    # Ok
    return $self->reply->json_ok({%ret});
}
sub public_key {
    my $self = shift;
    my $username = $self->stash('username');
    my $cachekey = $self->stash('cachekey');
    my $authdb = $self->authdb;
    my $public_key = $authdb->cached_user($username, $cachekey)->public_key // '';
    return $self->reply->json_error(404 => "E1100" => "No RSA public key found") unless length $public_key;
    return $self->reply->json_ok({public_key => $public_key});
}

1;

__END__
