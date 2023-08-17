# NAME

Web::Request::Role::AbsoluteUriFor - Construct an absolute URI honoring script\_name

# VERSION

version 1.004

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
    # https://yoursite.com/mountpoint/foo/bar

    # don't use the base-uri from $req by passing an explit additional value
    $req->absolute_uri_for({ controller=>'foo', action=>'bar' }, 'https://example.com');
    # https://example.com/mountpoint/foo/bar

# DESCRIPTION

`Web::Request::Role::AbsoluteUriFor` provides a method to calculate the absolute URI of a given controller/action, including the host name and handling various issues with `SCRIPTNAME` and reverse proxies.

## METHODS

### absolute\_uri\_for

    $req->absolute_uri_for( '/some/path' );
    $req->absolute_uri_for( $ref_uri_for );
    $req->absolute_uri_for( '/some/path', $base-url );

Construct an absolute URI out of `base_uri`, `script_name` and the
passed in string. You can also pass a ref, which will be resolved by
calling `uri_for` on the request object.

If you pass a second argument, this value will be used as the base-uri
instead of extracting it from the request. This can make sense when
you for exampel host a white lable service and need to generate
different links based on some value inside your app.

# THANKS

Thanks to

- [validad.com](https://www.validad.com/) for supporting Open Source.

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
