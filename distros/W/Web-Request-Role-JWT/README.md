# NAME

Web::Request::Role::JWT - Accessors for JSON Web Token (JWT) stored in psgix

# VERSION

version 1.003

# SYNOPSIS

    # Create a request handler
    package My::App::Request;
    use Moose;
    extends 'Web::Request';
    with 'Web::Request::Role::JWT';

    # Finally, in some controller action
    sub action_that_needs_a_user_stored_in_jwt {
        my ($self, $req) = @_;

        my $sub   = $req->requires_jwt_claim_sub;

        my $data  = $self->model->do_something( $sub );
        return $self->json_response( $data );
    }

# DESCRIPTION

`Web::Request::Role::JWT` provides a few accessor and helper methods
that make accessing JSON Web Tokens (JWT) stored in your PSGI `$env`
easier.

It works especially well when used with
[Plack::Middleware::Auth::JWT](https://metacpan.org/pod/Plack%3A%3AMiddleware%3A%3AAuth%3A%3AJWT), which will validate the token and
extract the payload into the PSGI `$env`.

# METHODS

## requires\_\* and logging

If a `requires_*` method fails, it will log an error via [Log::Any](https://metacpan.org/pod/Log%3A%3AAny).

## get\_jwt

    my $raw_token = $req->get_jwt;

Returns the raw token, so you can inspect it, or maybe pass it along to some other endpoint.

If you want to store your token somewhere else than the default `$env->{'psgix.token'}`, you have to provide another implementation
for this method.

## get\_jwt\_claims

    my $claims = $req->get_jwt_claims;

Returns all the claims as a hashref.

If you want to store your claims somewhere else than the default `$env->{'psgix.claims'}`, you have to provide another implementation
for this method.

## get\_jwt\_claim\_sub

    my $sub = $req->get_jwt_claim_sub;

Get the `sub` claim: [https://tools.ietf.org/html/rfc7519#section-4.1.2](https://tools.ietf.org/html/rfc7519#section-4.1.2)

## get\_jwt\_claim\_aud

    my $aud = $req->get_jwt_claim_aud;

Get the `aud` claim: [https://tools.ietf.org/html/rfc7519#section-4.1.3](https://tools.ietf.org/html/rfc7519#section-4.1.3)

## requires\_jwt

    my $raw_token = $req->requires_jwt;

Returns the raw token. If no token is available, throws a [HTTP::Throwable::Role::Status::Unauthorized](https://metacpan.org/pod/HTTP%3A%3AThrowable%3A%3ARole%3A%3AStatus%3A%3AUnauthorized) exception (aka HTTP Status 401)

## requires\_jwt\_claims

    my $claims = $req->requires_jwt_claims;

Returns all the claims as a hashref. If no claims are available, throws a [HTTP::Throwable::Role::Status::Unauthorized](https://metacpan.org/pod/HTTP%3A%3AThrowable%3A%3ARole%3A%3AStatus%3A%3AUnauthorized) exception (aka HTTP Status 401)

## requires\_jwt\_claim\_sub

    my $sub = $req->requires_jwt_claim_sub;

Returns the `sub` claim. If the `sub` claim is missing, throws a [HTTP::Throwable::Role::Status::Unauthorized](https://metacpan.org/pod/HTTP%3A%3AThrowable%3A%3ARole%3A%3AStatus%3A%3AUnauthorized) exception (aka HTTP Status 401)

## requires\_jwt\_claim\_aud

    my $aud = $req->requires_jwt_claim_aud;

Returns the `aud` claim. If the `aud` claim is missing, throws a [HTTP::Throwable::Role::Status::Unauthorized](https://metacpan.org/pod/HTTP%3A%3AThrowable%3A%3ARole%3A%3AStatus%3A%3AUnauthorized) exception (aka HTTP Status 401)

# THANKS

Thanks to

- [validad.com](https://www.validad.com/) for supporting Open Source.

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
