use strict;
use warnings;
use Test::More tests => 3;
use HTTP::Session::State::Null;
use HTTP::Session::Store::Test;
use HTTP::Session;
use CGI;

{
    my $session = HTTP::Session->new(
        state      => HTTP::Session::State::Null->new(),
        store      => HTTP::Session::Store::Test->new(),
        id         => 'HTTP::Session::ID::MD5',
        request    => CGI->new(),
        sid_length => 40,
    );
    is length($session->session_id), 32, 'because, md5_hex returns 32 bytes';
}

{
    my $session = HTTP::Session->new(
        state      => HTTP::Session::State::Null->new(),
        store      => HTTP::Session::Store::Test->new(),
        id         => 'HTTP::Session::ID::SHA1',
        request    => CGI->new(),
        sid_length => 40,
    );
    is length($session->session_id), 40, 'because, sha1_hex returns 40 bytes';
}

{
    my $session = HTTP::Session->new(
        state      => HTTP::Session::State::Null->new(),
        store      => HTTP::Session::Store::Test->new(),
        id         => 'HTTP::Session::ID::SHA1',
        request    => CGI->new(),
        sid_length => 40,
    );
    is length($session->session_id), 40, 'because, sha1_hex returns 40 bytes';
}

