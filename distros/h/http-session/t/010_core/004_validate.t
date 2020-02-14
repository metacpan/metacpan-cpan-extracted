use strict;
use warnings;
use Test::More tests => 2;
use t::Exception;
use HTTP::Session;
use HTTP::Session::State::Null;
use HTTP::Session::Store::Null;
use HTTP::Response;
use CGI;

sub {
    my $session = HTTP::Session->new(
        state => HTTP::Session::State::Null->new,
        store => HTTP::Session::Store::Null->new,
        request => CGI->new(),
    );
    my $res = HTTP::Response->new;
    throws_ok { $session->response_filter } qr/missing response/;
    $session->session_id('hoge');
    lives_ok { $session->response_filter($res) };
}->();

