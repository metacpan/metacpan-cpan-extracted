use strict;
use warnings;
use Test::More;

use_ok 'Unblock::WebSocket';
use_ok 'Unblock::WebSocket::Client';
use_ok 'Unblock::WebSocket::Server';
use_ok 'Unblock::WebSocket::Handshake';
use_ok 'Unblock::WebSocket::_Frame';

like $Unblock::WebSocket::VERSION, qr/\A[0-9]+\.[0-9]+\z/,
    'distribution version is defined';

done_testing;
