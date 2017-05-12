use strict;
use warnings;

use File::Temp qw/tempfile/;
use IO::Socket::INET;
use Net::EmptyPort qw/empty_port/;
use Test::More;
use Test::NoLeaks qw/noleaks/;
use Test::Warnings;

ok noleaks(
    code          => sub { },
    track_memory  => 1,
    track_fds     => 1,
    passes        => 2,
    warmup_passes => 1,
    ),
    "simple leak-less invocation";

my $cache;
ok noleaks(
    code => sub {
        $cache = [map { rand } (0 .. 5000)] unless $cache;
    },
    track_memory  => 1,
    track_fds     => 1,
    passes        => 10,
    warmup_passes => 1,
    ),
    "no leaks on warm-up cache";

ok noleaks(
    code => sub {
        [map { rand } (0 .. 15000)];
    },
    track_memory  => 1,
    track_fds     => 0,
    passes        => 5,
    warmup_passes => 0,
    tolerate_hits => 1,
    ),
    "tolerated way should not trigger memory leaks report";

ok noleaks(
    code => sub { my $x; $x = \$x; },
    track_memory  => 1,
    track_fds     => 1,
    passes        => 2,
    warmup_passes => 1,
    ),
    "small leak with small number of passes cannot be detected";

ok noleaks(
    code => sub { my $x; $x = \$x; },
    track_memory  => 1,
    track_fds     => 1,
    passes        => 15000,
    warmup_passes => 0,
    ),
    "small leak with lar number of passes should be detected";

my @leaked_fds;
ok !noleaks(
    code          => sub { push(@leaked_fds, tempfile); },
    track_memory  => 0,
    track_fds     => 1,
    passes        => 2,
    warmup_passes => 0,
    ),
    "non-closed temp-files cause FD leaks report";

my @leaked_sockets;
ok !noleaks(
    code => sub {
        my $s = IO::Socket::INET->new(
            Listen    => 5,
            LocalPort => empty_port,
            Proto     => 'tcp'
        );
        push(@leaked_sockets, $s);
    },
    track_memory  => 0,
    track_fds     => 1,
    passes        => 2,
    warmup_passes => 0,
    ),
    "non-closed sockets cause FD leaks report";

ok noleaks(
    code => sub {
        my $s = IO::Socket::INET->new(
            Listen    => 5,
            LocalPort => empty_port,
            Proto     => 'tcp'
        );
    },
    track_memory  => 0,
    track_fds     => 1,
    passes        => 2,
    warmup_passes => 0,
    ),
    "closed sockets DO NOT cause FD leaks report";

done_testing;
