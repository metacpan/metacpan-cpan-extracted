# NAME

Test::Mock::LWP::Conditional - stubbing on LWP request

# SYNOPSIS

    use LWP::UserAgent;
    use HTTP::Response;

    use Test::More
    use Test::Mock::LWP::Conditional;

    my $uri = 'http://example.com/';

    # global
    Test::Mock::LWP::Conditional->stub_request($uri => HTTP::Response->new(503));
    is LWP::UserAgent->new->get($uri)->code => 503;

    # lexical
    my $ua = LWP::UserAgent->new;
    $ua->stub_request($uri => sub { HTTP::Response->new(500) });
    is $ua->get($uri)->code => 500;
    is LWP::UserAgent->new->get($uri)->code => 503;

    # reset
    Test::Mock::LWP::Conditional->reset_all;
    is $ua->get($uri)->code => 200;
    is LWP::UserAgent->new->get($uri)->code => 200;

# DESCRIPTION

This module stubs out LWP::UserAgent's request.

# METHODS

- stub\_request($uri, $res)

    Sets stub response for requesed URI.

- reset\_all

    Clear all stub requests.

# AUTHOR

NAKAGAWA Masaki <masaki@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[Test::Mock::LWP](https://metacpan.org/pod/Test::Mock::LWP), [Test::Mock::LWP::Dispatch](https://metacpan.org/pod/Test::Mock::LWP::Dispatch), [Test::MockHTTP](https://metacpan.org/pod/Test::MockHTTP), [Test::LWP::MockSocket::http](https://metacpan.org/pod/Test::LWP::MockSocket::http)

[LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)

[https://github.com/bblimke/webmock](https://github.com/bblimke/webmock), [https://github.com/chrisk/fakeweb](https://github.com/chrisk/fakeweb)
