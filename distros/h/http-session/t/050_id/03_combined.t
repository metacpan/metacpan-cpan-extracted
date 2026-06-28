use strict;
use warnings;
use Test::More tests => 4;
use HTTP::Session::State::Null;
use HTTP::Session::Store::Test;
use HTTP::Session;
use CGI;

sub sid {
    my %extra = @_;
    return HTTP::Session->new(
        state   => HTTP::Session::State::Null->new(),
        store   => HTTP::Session::Store::Test->new(),
        request => CGI->new(),
        %extra,
    )->session_id;
}

is length(sid(id => 'HTTP::Session::ID::MD5',     sid_length => 40)), 32, 'md5_hex caps at 32 chars';
is length(sid(id => 'HTTP::Session::ID::SHA1',    sid_length => 40)), 40, 'sha1_hex provides 40 chars';
is length(sid(id => 'HTTP::Session::ID::Urandom', sid_length => 40)), 40, 'Urandom honors full length';
like sid(), qr{^[A-Za-z0-9_-]{32}$}, 'default backend is Urandom (url-safe, 32 chars)';
