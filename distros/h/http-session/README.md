# NAME

HTTP::Session - (DEPRECATED) simple session

# SYNOPSIS

    use HTTP::Session;

    my $session = HTTP::Session->new(
        store   => HTTP::Session::Store::Memcached->new(
            memd => Cache::Memcached->new({
                servers => ['127.0.0.1:11211'],
            }),
        ),
        state   => HTTP::Session::State::Cookie->new(
            name => 'foo_sid'
        ),
        request => $c->req,
    );

# DESCRIPTION

**This module is deprecated.** Use [Plack::Middleware::Session](https://metacpan.org/pod/Plack%3A%3AMiddleware%3A%3ASession) instead.

Yet another session manager.

easy to integrate with [PSGI](https://metacpan.org/pod/PSGI) =)

# METHODS

- my $session = HTTP::Session->new(store => $store, state => $state, request => $req)

    This method creates new instance of HTTP::Session.

    `store` is instance of HTTP::Session::Store::\*.

    `state` is instance of HTTP::Session::State::\*.

    `request` is duck typed object.`request` object should have `header`, `address`, `param`.
    You can use PSGI's $env instead.

    `id` selects the session-ID generator class (default:
    [HTTP::Session::ID::Urandom](https://metacpan.org/pod/HTTP%3A%3ASession%3A%3AID%3A%3AUrandom), which draws from [Crypt::URandom](https://metacpan.org/pod/Crypt%3A%3AURandom)). The
    `HTTP::Session::ID::MD5` and `HTTP::Session::ID::SHA1` backends are also
    supported; as of CVE-2026-3256 they hash cryptographically secure random bytes
    (from [Crypt::URandom](https://metacpan.org/pod/Crypt%3A%3AURandom)) instead of their former predictable time/PID/`rand()`
    input, while keeping their hexadecimal output. Each backend has its own
    session-ID alphabet: `Urandom` uses URL-safe Base64 (`[A-Za-z0-9_-]`), while
    `MD5` and `SHA1` use lowercase hexadecimal (`[0-9a-f]`).

    `sid_length` defaults to 32, which yields at least 128 bits of entropy with any
    backend (192 bits with `Urandom`). Lowering it is supported, but reduces the
    entropy of the session ID proportionally; values around 22 or below drop under
    the 128-bit level generally recommended for session identifiers.

- $session->html\_filter($html)

    filtering HTML

- $session->redirect\_filter($url)

    filtering redirect URL

- $session->header\_filter($res)

    filtering header

- $session->response\_filter($res)

    filtering response. this method runs html\_filter, redirect\_filter and header\_filter.

    $res should be PSGI's response array, instance of [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse), or [HTTP::Engine::Response](https://metacpan.org/pod/HTTP%3A%3AEngine%3A%3AResponse).

- $session->keys()

    keys of session.

- $session->get(key)

    get session item

- $session->set(key, val)

    set session item

- $session->remove(key)

    remove item.

- $session->as\_hashref()

    session as hashref.

- $session->expire()

    expire the session

- $session->regenerate\_session\_id(\[$delete\_old\])

    regenerate session id.remove old one when $delete\_old is true value.

- $session->finalize()

    commit the session data.

# CLEANUP SESSION

Some storage doesn't care the old session data.Please call $store->cleanup( $min ); manually.

# AUTHOR

Tokuhiro Matsuno &lt;tokuhirom AAJKLFJEF GMAIL COM>

# THANKS TO

    kazuhooku
    amachang
    walf443
    yappo
    nekokak

# REPOSITORY

I use github.
repo url is here [http://github.com/tokuhirom/http-session/tree/master](http://github.com/tokuhirom/http-session/tree/master)

# SEE ALSO

[Catalyst::Plugin::Session](https://metacpan.org/pod/Catalyst%3A%3APlugin%3A%3ASession), [Sledge::Session](https://metacpan.org/pod/Sledge%3A%3ASession)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
