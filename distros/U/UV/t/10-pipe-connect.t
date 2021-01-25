use strict;
use warnings;

use UV::Loop ();
use UV::Pipe ();

use Test::More;

use IO::Socket::UNIX;

# TODO: This test might not work on MSWin32. We might need to find a different
#   implementation, or just skip it?

my $path = "test-tmp.sock";
my $listensock = IO::Socket::UNIX->new(
    Local => $path,
    Listen => 1,
) or die "Cannot create listening socket - $@"; # yes $@
END { unlink $path; }

my $pipe = UV::Pipe->new;
isa_ok($pipe, 'UV::Pipe');

my $connect_cb_called;
my $req = $pipe->connect($path, sub { $connect_cb_called++ } );
isa_ok($req, 'UV::Req');

UV::Loop->default->run;

ok($connect_cb_called, 'connect callback was called');

is($pipe->getpeername, $path,
    'getpeername returns sockaddr');

my $shutdown_cb_called;
$pipe->shutdown(sub { $shutdown_cb_called++ } );

UV::Loop->default->run;

ok($shutdown_cb_called, 'shutdown callback was called');

done_testing();
