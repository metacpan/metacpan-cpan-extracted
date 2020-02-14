package t::CookieTest;
use strict;
use warnings;
use Test::More;
use t::Exception;
use HTTP::Session;
use HTTP::Session::Store::Test;
use HTTP::Session::State::Cookie;
use HTTP::Response;
use HTTP::Request;
use HTTP::Headers;

sub test {
    my ($class, $cgi) = @_;

    my $store = HTTP::Session::Store::Test->new(
        data => {
            bar => {}
        }
    );

    sub {
        local %ENV = (
            HTTP_COOKIE => 'http_session_sid=bar; path=/;',
        );

        my $session = HTTP::Session->new(
            store   => $store,
            state   => HTTP::Session::State::Cookie->new(),
            request => $cgi->new
        );
        is $session->session_id(), 'bar';
        my $res = HTTP::Response->new(200, 'foo');
        $session->response_filter($res);
        is $res->header('Set-Cookie'), 'http_session_sid=bar; path=/';
    }->();

    sub {
        my $session = HTTP::Session->new(
            store   => $store,
            state   => HTTP::Session::State::Cookie->new(),
            request => HTTP::Request->new(
                'GET',
                '/',
                HTTP::Headers->new(
                    Cookie => 'http_session_sid=bar; path=/;',
                ),
            ),
        );
        is $session->session_id(), 'bar';
    }->();

    sub {
        local $ENV{HTTP_COOKIE} = '';

        my $session = HTTP::Session->new(
            store   => $store,
            state   => HTTP::Session::State::Cookie->new(),
            request => $cgi->new
        );
        like $session->session_id(), qr/^[a-z0-9]{32}$/, 'cookie not found';
    }->();

    sub {
        local $ENV{HTTP_COOKIE} = 'foo_sid=bar; path=/admin/;';

        my $session = HTTP::Session->new(
            store => $store,
            state => HTTP::Session::State::Cookie->new(
                name    => 'foo_sid',
                path    => '/admin/',
                domain  => 'example.com',
            ),
            request => $cgi->new
        );
        is $session->session_id, 'bar';
        my $res = HTTP::Response->new(200, 'foo');
        $session->response_filter($res);
        is $res->header('Set-Cookie'), 'foo_sid=bar; domain=example.com; path=/admin/';
    }->();

    sub {
        local $ENV{HTTP_COOKIE} = 'foo_sid=bar; path=/admin/;';

        my $session = HTTP::Session->new(
            store => $store,
            state => HTTP::Session::State::Cookie->new(
                expires => '+1M',
                name    => 'foo_sid',
            ),
            request => $cgi->new
        );
        is $session->session_id, 'bar';

        {
            my $res = HTTP::Response->new(200, 'foo');
            $session->response_filter($res);
            like $res->header('Set-Cookie'), qr!foo_sid=bar; path=/; expires=[A-Z][a-z]{2}, \d+-[A-Z][a-z]{2}-\d{4} \d\d:\d\d:\d\d GMT!;
        }

        {
            my $res = HTTP::Response->new(200, 'foo');
            $session->header_filter($res);
            like $res->header('Set-Cookie'), qr!foo_sid=bar; path=/; expires=[A-Z][a-z]{2}, \d+-[A-Z][a-z]{2}-\d{4} \d\d:\d\d:\d\d GMT!;
        }
    }->();

    sub {
        local $ENV{HTTP_COOKIE} = 'foo_sid=bar; path=/admin/;';

	for my $option ([secure => 1], [HttpOnly => 1]) {
            my $session = HTTP::Session->new(
                store => $store,
                state => HTTP::Session::State::Cookie->new(
                    name    => 'foo_sid',
                    lc($option->[0]) => $option->[1],
                ),
                request => $cgi->new
            );
            my $res = HTTP::Response->new(200, 'foo');
            $session->response_filter($res);

            is $res->header('Set-Cookie'), 'foo_sid=bar; path=/; '. $option->[0], "@$option";
        }
    }->();

    sub {
        local $ENV{HTTP_COOKIE} = 'foo_sid=bar; path=/admin/;';

	for my $option ([SameSite => 'None'], [SameSite => 'Lax'], [SameSite => 'Strict']) {
          SKIP: {
            my $session = HTTP::Session->new(
                store => $store,
                state => HTTP::Session::State::Cookie->new(
                    name    => 'foo_sid',
                    lc($option->[0]) => $option->[1],
                ),
                request => $cgi->new
            );
            my $res = HTTP::Response->new(200, 'foo');
            $session->response_filter($res);

            skip "CGI::Simple 1.22 doesn't support SameSite=None", 1 if $option->[1] eq 'None' and $HTTP::Session::State::Cookie::COOKIE_CLASS eq 'CGI::Simple::Cookie';
            my $option_string = $option->[0] . '=' . $option->[1];
            is $res->header('Set-Cookie'), 'foo_sid=bar; path=/; '. $option_string, "@$option";
          }
        }
    }->();


    sub {
        local $ENV{HTTP_COOKIE} = 'foo_sid=bar; path=/admin/;';

        my $session = HTTP::Session->new(
            store => $store,
            state => HTTP::Session::State::Cookie->new(
                name    => 'foo_sid',
                path    => '/admin/',
                domain  => 'example.com',
                secure  => 1,
            ),
            request => $cgi->new
        );
        is $session->session_id, 'bar';
        my $res = HTTP::Response->new(200, 'foo');
        $session->response_filter($res);
        is $res->header('Set-Cookie'), 'foo_sid=bar; domain=example.com; path=/admin/; secure';
    }->();

    sub {
        local $ENV{HTTP_COOKIE} = 'foo_sid=bar; path=/admin/;';

        my $session = HTTP::Session->new(
            store => $store,
            state => HTTP::Session::State::Cookie->new(),
            request => $cgi->new
        );
        throws_ok {$session->state->response_filter() } qr/missing session_id/;
    }->();

    sub {
        local $ENV{HTTP_COOKIE} = 'foo_sid=bar; path=/admin/;';

        my $session = HTTP::Session->new(
            store => $store,
            state => HTTP::Session::State::Cookie->new(),
            request => $cgi->new
        );
        is $session->html_filter('<a href="/">foo</a>'), '<a href="/">foo</a>', 'html_filter';
    }->();

    sub {
        {
            package TestRequest;
            sub new { bless {}, shift };
            sub header {}
        };
        delete $ENV{HTTP_COOKIE};

        my $session = HTTP::Session->new(
            store   => $store,
            state   => HTTP::Session::State::Cookie->new(),
            request => TestRequest->new
        );
        like $session->session_id(), qr/^[a-z0-9]{32}$/, 'cookie not found';
    }->();
}

1;
