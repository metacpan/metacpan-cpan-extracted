NAME

    URI::FromHash - Build a URI from a set of named parameters

VERSION

    version 0.05

SYNOPSIS

      use URI::FromHash qw( uri );
    
      my $uri = uri(
          path  => '/some/path',
          query => { foo => 1, bar => 2 },
      );

DESCRIPTION

    This module provides a simple one-subroutine "named parameters" style
    interface for creating URIs. Underneath the hood it uses URI.pm, though
    because of the simplified interface it may not support all possible
    options for all types of URIs.

    It was created for the common case where you simply want to have a
    simple interface for creating syntactically correct URIs from known
    components (like a path and query string). Doing this using the native
    URI.pm interface is rather tedious, requiring a number of method calls,
    which is particularly ugly when done inside a templating system such as
    Mason or TT2.

FUNCTIONS

    This module provides two functions both of which are optionally
    exportable:

 uri( ... ) and uri_object( ... )

    Both of these functions accept the same set of parameters, except for
    one additional parameter allowed when calling uri().

    The uri() function simply returns a string representing a canonicalized
    URI based on the provided parameters. The uri_object() function returns
    new a URI.pm object based on the given parameters.

    These parameters are:

      * scheme

      The URI's scheme. This is optional, and if none is given you will
      create a schemeless URI. This is useful if you want to create a URI
      to a path on the same server (as is commonly done in <a> tags).

      * host

      * port

      * path

      The path can be either a string or an array reference.

      If an array reference is passed each defined member of the array will
      be joined by a single forward slash (/).

      If you are building a host-less URI and want to include a leading
      slash then make the first element of the array reference an empty
      string (q{}).

      You can add a trailing slash by making the last element of the array
      reference an empty string.

      * username

      * password

      * fragment

      All of these are optional strings which can be used to specify that
      part of the URI.

      * query

      This should be a hash reference of query parameters. The values for
      each key may be a scalar or array reference. Use an array reference
      to provide multiple values for one key.

      * query_separator

      This option is can only be provided when calling uri(). By default,
      it is a semi-colon (;).

BUGS

    Please report any bugs or feature requests to
    bug-uri-fromhash@rt.cpan.org, or through the web interface at
    http://rt.cpan.org. I will be notified, and then you'll automatically
    be notified of progress on your bug as I make changes.

AUTHOR

    Dave Rolsky <autarch@urth.org>

COPYRIGHT AND LICENSE

    This software is Copyright (c) 2015 by Dave Rolsky.

    This is free software, licensed under:

      The Artistic License 2.0 (GPL Compatible)

