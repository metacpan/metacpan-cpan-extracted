use Test2::V0;
use POSIX ();

use Test2::Harness2::ChildSubReaper qw/set_child_subreaper have_subreaper_support/;

skip_all "Linux-only"                         unless $^O eq 'linux';
skip_all "no subreaper support in this build" unless have_subreaper_support();

# Run in a fresh forked process so the test process itself is not left
# with the subreaper flag set.
subtest enable => sub {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $ok = set_child_subreaper(1);
        POSIX::_exit($ok ? 0 : 1);
    }
    waitpid($pid, 0);
    is($? >> 8, 0, 'set_child_subreaper(1) succeeded in a fresh process');
};

subtest disable => sub {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        set_child_subreaper(1);
        my $ok = set_child_subreaper(0);
        POSIX::_exit($ok ? 0 : 1);
    }
    waitpid($pid, 0);
    is($? >> 8, 0, 'set_child_subreaper(0) succeeded');
};

done_testing;
