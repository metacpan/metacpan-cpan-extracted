URL::Signature - Sign URLs to tamper-proof them
=============================================

This module is a simple wrapper around [Digest::HMAC][1]
and [URI][2]. It is intended to make it simple to do integrity
checks on URLs (and other URIs as well).


URL Tampering?
--------------

Sometimes you want to provide dynamic resources in your server based on
path or query parameters. An image server, for instance, might want to
provide different sizes and effects for images like so:

    http://myserver/images/150x150/flipped/perl.png

A malicious user might take advantage of that to try and traverse through
options or even [DoS][3] your application by forcing it to do tons of
unnecessary processing and filesystem operations.

One way to prevent this is to sign your URLs with HMAC and a secret key.
In this approach, you authenticate your URL and append the resulting code
to it. The above URL could look like this:

    http://myserver/images/041da974ac0390b7340/150x150/flipped/perl.png

or

    http://myserver/images/150x150/flipped/perl.png?k=041da974ac0390b7340

This way, whenever your server receives a request, it can check the URL
to see if the provided code matches the rest of the path. If a malicious
user tries to tamper with the URL, the provided code will be a mismatch
to the tampered path and you'll be able to catch it early on.

It is worth noticing that, when in `query` mode, the
**key order is not important for validation**. That means the following
URIs are all considered valid (for the same given secret key):

    foo/bar?a=1&b=2&k=SOME_KEY
    foo/bar?a=1&k=SOME_KEY&b=2
    foo/bar?b=2&k=SOME_KEY&a=1
    foo/bar?b=2&a=1&k=SOME_KEY
    foo/bar?k=SOME_KEY&a=1&b=2
    foo/var?k=SOME_KEY&b=2&a=1


USAGE SAMPLE
------------

    use URL::Signature;
    my $obj = URL::Signature->new( key => 'My secret key' );

    # get a URI object with the HMAC signature attached to it
    my $url = $obj->sign( '/path/to/somewhere?data=stuff' );

    # if path is valid, get a URI object without the signature in it
    my $path = 'www.example.com/1b23094726520/some/path?data=value&other=extra';
    my $validated = $obj->validate($path);

For a much more detailed explanation, including customization choices
and list of raised exceptions, please refer to the full documentation
at:

    http://metacpan.org/module/URL::Signature

That same documentation will also be available to you after installation
at the command line. Just type:

    perldoc URL::Signature

after the the module is installed.


INSTALLATION
------------

To install this module, you should probably use a CPAN client such as
'cpan':

    $ cpan
    cpan> install URL::Signature

or 'cpanm':

    $ cpanm URL::Signature


For the manual installation, download/unpack this distribution and,
within the base directory, run the following commands:

	perl Makefile.PL
	make
	make test
	make install


COPYRIGHT AND LICENCE

Copyright (C) 2013, Breno G. de Oliveira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


[1]: https://metacpan.org/module/Digest::HMAC
[2]: https://metacpan.org/module/URI
[3]: https://en.wikipedia.org/wiki/Denial-of-service_attack

