use strict;
use warnings;

use UV::Loop ();
use UV::Pipe ();

use Test::More;

use IO::Socket::UNIX;

# TODO: This test might not work on MSWin32. We might need to find a different
#   implementation, or just skip it?

my $path = "test-tmp.sock";

my $pipe = UV::Pipe->new;
isa_ok($pipe, 'UV::Pipe');

$pipe->bind($path);
END { unlink $path; }

ok(-S $path, 'Path created as a socket');

my $connection_cb_called;
sub connection_cb {
    my ($self) = @_;
    $connection_cb_called++;

    my $client = $self->accept;

    isa_ok($client, 'UV::Pipe');
    is($client->getsockname, $path, 'getsockname returns sockaddr');

    $self->close;
    $client->close;
}

$pipe->listen(5, \&connection_cb);

my $sock = IO::Socket::UNIX->new(
    Peer => $path,
) or die "Cannot connect socket - $@"; # yes $@

UV::Loop->default->run;

ok($connection_cb_called, 'connection callback was called');

done_testing();
