#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use IO::Socket::INET;
use YAHC;
use EV;

my $host = 'localhost',
my $port = '5000';
my $message = 'TEST';

pipe(my $rh, my $wh) or die "failed to pipe: $!";

my $pid = fork;
defined $pid or die "failed to fork: $!";
if ($pid == 0) {
    my $sock = IO::Socket::INET->new(
        Proto       => 'tcp',
        LocalHost   => '0.0.0.0',
        LocalPort   => $port,
        ReuseAddr   => 1,
        Blocking    => 1,
        Listen      => 1,
    ) or die "failed to create socket in child: $!";

    local $SIG{ALRM} = sub { exit 0 };
    alarm(20); # 20 sec of timeout

    close($wh); # signal parent process
    close($rh);

    my $client = $sock->accept or die "failed to accept connection in child: $!";
    $client && $client->send($message);
    exit 0;
}

# wait for child process
close($wh);
sysread($rh, my $b = '', 1);
close($rh);

my ($yahc, $yahc_storage) = YAHC->new;
my $conn = $yahc->request({
    host => $host,
    port => $port,
    keep_timeline => 1,
    _test => 1,
});

$yahc->_set_init_state($conn->{id});
$yahc->run(YAHC::State::CONNECTED(), $conn->{id});

ok($conn->{state} == YAHC::State::CONNECTED(), "check state")
    or diag("got:\n" . YAHC::_strstate($conn->{state}) . "\nexpected:\nSTATE_CONNECTED\ntimeline: " . Dumper($conn->{timeline}));

my $fh = $yahc->{watchers}{$conn->{id}}{_fh};
ok(defined $fh, "socket is defined");

if (defined $fh) {
    my $buf = '';
    while (1) {
        my $rlen = sysread($fh, $buf, length($message));
        next if !defined($rlen) && ($! == POSIX::EAGAIN || $! == POSIX::EWOULDBLOCK || $! == POSIX::EINTR);
        last;
    }

    ok($buf eq $message, "received expected message")
        or diag("got:\n$buf\nexpected:\n$message");
}

END { kill 'KILL', $pid if $pid }

done_testing;
