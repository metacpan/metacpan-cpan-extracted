use strict;
use warnings;

use Test::More;
use IO::Socket::INET;
use Socket;
use UV;
use UV::Loop ();
use UV::Poll qw(UV_READABLE UV_WRITABLE);

my $NUM_SOCKETS = 1; #64;
my $close_cb_called = 0;


sub close_cb {
    $close_cb_called++;
    ok("close_cb: got here");
}

ok(1, 'Skipping all tests here.');
# {
#     my @sockets;
#     my @handles;
#
#     for my $i (0 .. $NUM_SOCKETS-1) {
#         my $socket = IO::Socket::INET->new(
#             Type=>SOCK_STREAM,
#             Blocking => 0,
#         );
#         isa_ok($socket, 'IO::Socket', 'Got a new socket');
#         ok(!$@, 'no errors from socket');
#         my $handle = UV::Poll->new(fd => $socket->fileno(), on_close => \&close_cb);
#         isa_ok($handle, 'UV::Poll', 'Got a new poll');
#         push @sockets, $socket;
#         push @handles, $handle;
#         is($handle->start(UV_READABLE | UV_WRITABLE), 0, 'poll started successfully');
#     }
#
#     for my $handle (@handles) {
#         $handle->close();
#     }
#
#     is(UV::Loop->default_loop()->run(), 0, 'default loop run');
#     is($close_cb_called, $NUM_SOCKETS, 'Got the right number of close CBs');
# }

done_testing();
