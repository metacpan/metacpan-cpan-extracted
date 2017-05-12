use strict;
use warnings;
use Test::More tests => 7;
use IO::Pipe;

my $pipe = IO::Pipe->new;

if (my $pid = fork()) { # Parent
    diag "Child is $pid\n";
    $pipe->reader();
    while (<$pipe>) {
        my ($level, $msg) = m/(\w+) (.+)/;
        like $level, qr/WARN|FATAL/, "Got $level";
        like $msg, qr/Hellow|Blabla/, "Got $msg";
    }
    ok($pipe->close, "Closed the pipe");
    ok(!$pipe->close, "Reclosing doesn't work");
    my $ripped = wait; # just to be sure
    my $exit_status = $? >> 8;
    ok($exit_status, "child died");
}
elsif (defined $pid) { # Child
    $pipe->writer();
    *STDOUT = *STDERR = $pipe;
    $pipe->autoflush(1);
    print "WARN Hellow\n";
    die "FATAL Blabla\n";
}

