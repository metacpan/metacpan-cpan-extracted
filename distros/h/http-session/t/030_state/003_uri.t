use strict;
use warnings;
use Test::More;
plan skip_all => 'this test requires HTML::StickyQuery' unless eval "use HTML::StickyQuery; 1;";
plan tests => 11;
use t::Exception;
use HTTP::Session;
use HTTP::Session::Store::Test;
require HTTP::Session::State::URI;
use HTTP::Response;
use CGI;

my $state = HTTP::Session::State::URI->new();

sub {
    my $session = HTTP::Session->new(
        store   => HTTP::Session::Store::Test->new(
            data => {
                bar =>  { }
            },
        ),
        state   => HTTP::Session::State::URI->new(),
        request => CGI->new({ sid => 'bar' }),
    );
    is $session->session_id(), 'bar';

    sub {
        my $res = HTTP::Response->new(200, 'ok', HTTP::Headers->new(), '<a href="/">foo</a>');
        $session->response_filter($res);
        is $res->content, '<a href="/?sid=bar">foo</a>';
    }->();

    sub {
        my $res = HTTP::Response->new(200, 'ok', HTTP::Headers->new(), '<form action="/"></form>');
        $session->response_filter($res);
        is $res->content, qq{<form action="/">\n<input type="hidden" name="sid" value="bar" /></form>};
    }->();

    sub {
        is $session->html_filter('<form action="/"></form>'), qq{<form action="/">\n<input type="hidden" name="sid" value="bar" /></form>};
    }->();

    sub {
        my $res = HTTP::Response->new(302, 'ok', HTTP::Headers->new(Location => 'http://example.com/'));
        $session->response_filter($res);
        is $res->header('Location'), q{http://example.com/?sid=bar};
    }->();

    sub {
        is $session->redirect_filter('http://example.com/'), 'http://example.com/?sid=bar';
    }->();

    sub {
        my $res = HTTP::Response->new(404, 'not found');
        $session->response_filter($res);
        ok "not found";
    }->();

    sub {
        my $res = HTTP::Response->new(302, 'no location');
        $session->response_filter($res);
        is $res->code, 302, 'no locaiton';
    }->();

    sub {
        my $res = HTTP::Response->new(200, 'binary');
        $res->content_type('image/jpeg');
        $res->content("\x00<form>");
        $session->response_filter($res);
        is $res->content, "\x00<form>";
    }->();

    throws_ok { $session->state->get_session_id }  qr/missing req/;
    throws_ok { $session->state->response_filter } qr/missing session_id/;
}->();

