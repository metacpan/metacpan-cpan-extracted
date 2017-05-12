# NAME

Test::OpenID::Consumer - setup a simulated OpenID consumer

# SYNOPSIS

Test::OpenID::Consumer will provide a consumer to test your OpenID server
against.  To use it, do something like this:

    use Test::More tests => 1;
    use Test::OpenID::Consumer;
    my $consumer = Test::OpenID::Consumer->new;
    my $url_root = $consumer->started_ok("server started ok");

    $consumer->verify_ok('http://server/identity/openid');

# METHODS

## new

Create a new test OpenID consumer

## ua \[OBJECT\]

Get/set the LWP useragent to use for fetching pages.  Defaults to an instance of
[LWP::UserAgent::Paranoid](https://metacpan.org/pod/LWP::UserAgent::Paranoid) with localhost whitelisted.

## started\_ok

Test whether the consumer's server started, and if it did, return the URL
it's at.

# METHODS

## verify\_ok URL \[TEST\_NAME\]

Attempts to verify the given OpenID.  At the moment, the verification MUST
NOT require any logging in or setup, but it may be supported in the future.

## verify\_cancelled URL \[TEST\_NAME\]

Like [verify\_ok](https://metacpan.org/pod/verify_ok), but the test passes if the OpenID verification process is
cancelled (i.e. the user chose not to trust the authenticating site).

## verify\_invalid URL \[TEST\_NAME\]

Like [verify\_ok](https://metacpan.org/pod/verify_ok) but the test passes if the OpenID client is unable to find
a valid OpenID identity at the URL given.

# INTERAL METHODS

These methods implement the HTTP server (see [HTTP::Server::Simple](https://metacpan.org/pod/HTTP::Server::Simple))
that the consumer uses.  You shouldn't call them.

## handle\_request

# AUTHORS

Thomas Sibley <trs@bestpractical.com>

# COPYRIGHT

Copyright (c) 2007, Best Practical Solutions, LLC. All rights reserved.

# LICENSE

You may distribute this module under the same terms as Perl 5.8 itself.
