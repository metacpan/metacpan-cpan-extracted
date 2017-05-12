use strict;
use warnings;
use utf8;
use Test::Kantan;

my $pid = fork();
die $! unless defined $pid;
if ($pid) { # parent
    subtest 'Heh', sub {
        ok { 1 }; # Parent
        diag "Diagnostic from parent";
        waitpid($pid, 0);
    };
} else {
    ok { 0 }; # Child
    diag "Diagnostic from child";
    exit 0;
}

done_testing;

