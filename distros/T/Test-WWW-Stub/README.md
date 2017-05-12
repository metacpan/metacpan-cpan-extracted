[![Build Status](https://travis-ci.org/astj/p5-Test-WWW-Stub.svg?branch=master)](https://travis-ci.org/astj/p5-Test-WWW-Stub)
# NAME

Test::WWW::Stub - Block and stub specified URL for LWP

# SYNOPSIS

    # External http(s) access via LWP is blocked by just declaring 'use Test::WWW::Stub';
    # Note that 'require Test::WWW::Stub' or 'use Test::WWW::Stub ()' doesn't block external access.
    use Test::WWW::Stub;

    my $ua = LWP::UserAgent->new;

    my $stubbed_res = [ 200, [], ['okay'] ];

    {
        my $guard = Test::WWW::Stub->register(q<http://example.com/TEST>, $stubbed_res);

        is $ua->get('http://example.com/TEST')->content, 'okay';
    }
    isnt $ua->get('http://example.com/TEST')->content, 'okay';

    {
        # registering in void context doesn't create guard.
        Test::WWW::Stub->register(q<http://example.com/HOGE/>, $stubbed_res);

        is $ua->get('http://example.com/HOGE')->content, 'okay';
    }
    is $ua->get('http://example.com/HOGE')->content, 'okay';

    {
        # You can also use regexp for uri
        my $guard = Test::WWW::Stub->register(qr<\A\Qhttp://example.com/MATCH/\E>, $stubbed_res);

        is $ua->get('http://example.com/MATCH/hogehoge')->content, 'okay';
    }

    {
        # you can unstub and allow external access temporary
        my $unstub_guard = Test::WWW::Stub->unstub;

        # External access occurs!!
        ok $ua->get('http://example.com');
    }

    my $last_req = Test::WWW::Stub->last_request; # Plack::Request
    is $last_req->uri, 'http://example.com/MATCH/hogehoge';

    Test::WWW::Stub->requested_ok('GET', 'http://example.com/TEST'); # passes

# DESCRIPTION

Test::WWW::Stub is a helper module to block external http(s) request and stub some specific requests in your test.

Because this modules uses [LWP::Protocol::PSGI](https://metacpan.org/pod/LWP::Protocol::PSGI) internally, you don't have to modify target codes using [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent).

# METHODS

- `register`

        my $guard = Test::WWW::Stub->register( $uri_or_re, $app_or_res );

    Registers a new stub for URI `$uri_or_re`.
    If called in void context, it simply registers the stub.
    Otherwise,it returns a new guard which drops the stub on destroyed.

    `$uri_or_re` is either an URI string or a compiled regular expression for URI.
    `$app_or_res` is a PSGI response array ref, or a code ref which returns a PSGI response array ref.
    If `$app_or_res` is a code ref, requests are passed to the code ref following syntax:

        my $req = Plack::Request->new($env);
        $app_or_res->($env, $req);

    Once registered, `$app_or_res` will be return from LWP::UserAgent on requesting certain URI matches `$uri_or_re`.

- `requested_ok`

        Test::WWW::Stub->requested_ok($method, $uri);

    Passes when `$uri` has been requested with `$method`, otherwise fails and dumps requests handled by Test::WWW::Stub.

    This method calls `Test::More::ok` or `Test::More::diag` internally.

- `requests`

        my @requests = Test::WWW::Stub->requests;

    Returns an array of [Plack::Request](https://metacpan.org/pod/Plack::Request) which is handled by Test::WWW::Stub.

- `last_request`

        my $last_req = Test::WWW::Stub->last_request;

    Returns a Plack::Request object last handled by Test::WWW::Stub.

    This method is same as `[Test::WWW::Stub->requests]->[-1]`.

- `last_request_for`

        my $last_req = Test::WWW::Stub->last_request_for($method, $uri);

    Returns a `Plack::Request` object last handled by Test::WWW::Stub and matched given HTTP method and URI.

- `clear_requests`

        Test::WWW::Stub->clear_requests;

    Clears request history of Test::WWW::Stub.

    `[Test::WWW::Stub->requests]` becomes empty just after this method called.

- `unstub`

        my $unstub_guard = Test::WWW::Stub->unstub;

    Unregister stub and enables external access, and returns a guard object which re-enables stub on destroyed.

    In constrast to `register`, this method doesn't work when called in void context.

# LICENSE

Copyright (C) Hatena Co., Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Asato Wakisaka <asato.wakisaka@gmail.com>

Original implementation written by suzak.
