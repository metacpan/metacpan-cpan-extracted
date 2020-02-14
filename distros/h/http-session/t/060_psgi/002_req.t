use strict;
use warnings;
use Test::Requires;
use Test::More tests => 1;
use HTTP::Session;
use HTTP::Session::State::Cookie;
use HTTP::Session::Store::Test;

# -------------------------------------------------------------------------
# state::cookie

do {
    my $session = HTTP::Session->new(
        state   => HTTP::Session::State::Cookie->new(),
        store   => HTTP::Session::Store::Test->new(
            data => {
                '7e328ddf45df42ca7cc89c88a95fc2af' => { }
            },
        ),
        request => {HTTP_COOKIE => 'http_session_sid=7e328ddf45df42ca7cc89c88a95fc2af; path=/'},
    );
    is $session->session_id, '7e328ddf45df42ca7cc89c88a95fc2af';
};

