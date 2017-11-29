# NAME

Test::WWW::Mechanize::Catalyst::WithContext - T::W::M::C can now give you $c

<div>
    <p>
    <a href="https://travis-ci.org/simbabque/Test-WWW-Mechanize-Catalyst-WithContext"><img src="https://travis-ci.org/simbabque/Test-WWW-Mechanize-Catalyst-WithContext.svg?branch=master"></a>
    <a href='https://coveralls.io/github/simbabque/Test-WWW-Mechanize-Catalyst-WithContext?branch=master'><img src='https://coveralls.io/repos/github/simbabque/Test-WWW-Mechanize-Catalyst-WithContext/badge.svg?branch=master' alt='Coverage Status' /></a>
    <a href='https://kritika.io/users/simbabque/repos/6965918834838520/heads/master/'><img src='https://kritika.io/users/simbabque/repos/6965918834838520/heads/master/status.svg' alt='Kritika Analysis Status' /></a>
    </p>
</div>

# VERSION

Version 0.03

# SYNOPSIS

    use Test::WWW::Mechanize::Catalyst::WithContext;

    my $mech = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'Catty' );

    $mech->get_ok("/");
    is $mech->ctx->stash->{foo}, "bar", "foo got set to bar";

    $mech->post_ok("login", { u => "test", p => "secret" });
    my $c = $mech->ctx; # $c is a Catalyst context
    is $c->session->{stuff}, "something", "things are in the session";

# DESCRIPTION

Test::WWW::Mechanize::Catalyst::WithContext is a subclass of [Test::WWW::Mechanize::Catalyst](https://metacpan.org/pod/Test::WWW::Mechanize::Catalyst)
that can give you the `$c` context object of the request you just did. This is useful for
testing if things ended up in the stash correctly, if the session got filled without reaching
into the persistence layer or to grab an instance of a model, view or controller to do tests
on them. Since the cookie jar of your `$mech` will be used to fetch the context, things
like being logged into your app will be taken into account.

Besides that, it's just the same as [Test::WWW::Mechanize::Catalyst](https://metacpan.org/pod/Test::WWW::Mechanize::Catalyst). It inherits everything
and does not overwrite any other functionality than the request making. See the docs of
[Test::WWW::Mechanize::Catalyst](https://metacpan.org/pod/Test::WWW::Mechanize::Catalyst) for more details.

# ATTRIBUTES

## ctx

## c

Contains the context object for the most recent request. `ctx` and `c` are equivalent. Pick
the one you feel more comfortable with.

    is $mech->ctx->stash->{foo}, "bar", "foo got set to bar";
    is $mech->c->stash->{foo}, "bar", "foo got set to bar";   # equivalent
    

If you need to keep an old context around to compare things before and after a request,
assign it to a variable. The below example is contrived, but illustrates the idea.

    $mech->get_ok("/cart");
    my $first_c = $mech->ctx;

    $mech->get_ok("/cart/add/some_product");
    isnt $first_c->cart->sum_total, $mech->ctx->cart->sum_total, "total cart value changed";

If you call this before you have made any requests, it will return `undef`. It will also
return `undef` if there was no Catalyst context, which is the case if the request
was handled by the Plack layer directly.

# METHODS

## get\_context($url)

This method was **DEPRECATED!** in version 0.03 and will likely be removed in a future version.
Use [`$mech->ctx`](#ctx) instead.

Does a GET request on `$url` and returns the [HTTP::Response](https://metacpan.org/pod/HTTP::Response) and the request context `$c`.

    my ( $res, $c ) = $mech->get_context('/');

This is not a `get_ok` and does not create test output.

# EXAMPLES

The following section gives a few examples where it's useful to have `$c`.

## Are we loading the right template?

If the content that comes out of your application does not really contain any distinct markers
it's very hard to check if the right stuff got rendered. Instead of trying to find something
in your HTML that helps you identify the right page with one of the content checking methods like
`content_like`, you can just look at the template name in the stash. Of course that doesn't tell
you if it got rendered successfully, but it does tell you which template the controller decided
should be rendered.

    $mech->get_ok('/hard/to/verify/page);
    is $mech->ctx->stash->{template}, 'hard_to_verify.tt2', 'the right template got selected';

## Checking what's in the session without talking to the store

If you want to look at values in the session before and after some action, you would typically
go and connect to the session store and peek around. For that, you need to know the type of the
store, how to connect to it, and your current test user's session id. This is relatively trivial
if a database (e.g. with [Test::DBIx::Class](https://metacpan.org/pod/Test::DBIx::Class)), but gets more complicated when you're not mocking
the store and it's something a little more esoteric. Of course you could use a different store for
your unit tests, but maybe you don't want to do that.

Enter Test::WWW::Mechanize::Catalyst::WithContext. Just grab the context before and after you
perform your action and look at the sessions.

    $mech->get('/'); # or some other url
    my $c_before = $mech->ctx;

    $mech->get('/change/session');
    my $c_after = $mech->ctx;
    isnt $c_before->session->{foo}, $c_after->session->{foo}, 'foo got changed';

Of course this could be arbitrarily complex.

# BUGS

If you find any bugs please [open an issue on github](https://github.com/simbabque/Test-WWW-Mechanize-Catalyst-WithContext/issues).

# SEE ALSO

- [Test::WWW::Mechanize::Catalyst](https://metacpan.org/pod/Test::WWW::Mechanize::Catalyst)
- [Test::WWW::Mechanize](https://metacpan.org/pod/Test::WWW::Mechanize)
- [WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize)
- [Catalyst::Test](https://metacpan.org/pod/Catalyst::Test)
- [Catalyst](https://metacpan.org/pod/Catalyst)

# ATTRIBUTION

This module borrows parts of its test suite from [Test::WWW::Mechanize::Catalyst](https://metacpan.org/pod/Test::WWW::Mechanize::Catalyst).

# AUTHOR

simbabque <simbabque@cpan.org>

# CONTRIBUTORS

- Robert Rothenberg

# LICENSE

Copyright (C) simbabque.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
