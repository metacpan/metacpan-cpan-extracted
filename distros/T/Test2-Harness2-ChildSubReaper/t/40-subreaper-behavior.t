use Test2::V0;
use POSIX ();

use Test2::Harness2::ChildSubReaper qw/set_child_subreaper have_subreaper_support/;

skip_all "no subreaper support in this build" unless have_subreaper_support();

# End-to-end check that the subreaper flag actually causes an orphaned
# grandchild to reparent to us, not to init.
#
# Run the whole experiment in a forked subject so we don't leave this
# test process permanently marked as a subreaper.

my $subject_pid = fork // die "fork: $!";
if (!$subject_pid) {
    set_child_subreaper(1) or POSIX::_exit(10);

    my $child = fork // POSIX::_exit(11);
    if (!$child) {
        # Child forks a grandchild and exits immediately; the grandchild
        # becomes orphaned. With PR_SET_CHILD_SUBREAPER, the grandchild
        # should reparent to the subject (us), not to PID 1.
        my $grandchild = fork // POSIX::_exit(12);
        if (!$grandchild) {
            # Grandchild: give the middle child time to exit so we get
            # orphaned, then exit with a recognizable status.
            sleep 1;
            POSIX::_exit(42);
        }

        # Middle child exits right away to orphan the grandchild.
        POSIX::_exit(0);
    }

    # Reap both descendants. Without subreaper support the grandchild
    # would have been reparented to init(1) and we would never see it.
    my %saw;
    while ((my $reaped = waitpid(-1, 0)) > 0) {
        $saw{$reaped} = $?;
    }

    # We must have seen at least two distinct pids (child + grandchild),
    # and exactly one of them must have exited with status 42.
    my @statuses       = values %saw;
    my $got_grandchild = grep { ($_ >> 8) == 42 } @statuses;
    POSIX::_exit(50) unless keys(%saw) >= 2;
    POSIX::_exit(51) unless $got_grandchild == 1;

    POSIX::_exit(0);
}

waitpid($subject_pid, 0);
my $code = $? >> 8;
is($code, 0, "subject reaped its orphaned grandchild (exit $code)");

done_testing;
