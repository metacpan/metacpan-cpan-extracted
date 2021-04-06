# NAME

Web::Request::Role::AbsoluteUriFor - Construct an absolute URI honoring script\_name

# VERSION

version 1.003

# SYNOPSIS

    # Create a request handler
    package My::App::Request;
    use Moose;
    extends 'Web::Request';
    with 'Web::Request::Role::AbsoluteUriFor';

    # Make sure your app uses your request handler, e.g. using OX:
    package My::App::OX;
    sub request_class {'My::App::Request'}

    # in some controller action:

    # redirect
    $req->absolute_uri_for({ controller=>'foo', action=>'bar' });
    # http://yoursite.com/mountpoint/foo/bar

# DESCRIPTION

`Web::Request::Role::AbsoluteUriFor` provides a method to calculate the absolute URI of a given controller/action, including the host name and handling various issues with `SCRIPTNAME` and reverse proxies.

## METHODS

### absolute\_uri\_for

    $req->absolute_uri_for( '/some/path' );
    $req->absolute_uri_for( $ref_uri_for );

Construct an absolute URI out of `base_uri`, `script_name` and the
passed in string.  You can also pass a ref, which will be resolved by
calling `uri_for` on the request object.

# THANKS

Thanks to

- [validad.com](https://www.validad.com/) for supporting Open Source.

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
