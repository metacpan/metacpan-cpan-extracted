use strict;
use warnings;

use Test::More;
use POSIX qw(ECHILD EINTR);

# B6: BackgroundInterrupt::running() must distinguish waitpid's -1 errno cases.
# ECHILD (and a positive reap) mean the child is gone; EINTR means the call was
# interrupted and says nothing about the child, so it must NOT latch the handle
# as stopped. waitpid is a builtin, so we override CORE::GLOBAL::waitpid in a
# BEGIN before the module compiles - then running()'s call binds to this mock.
# The override is contained to this test process.

our ($MOCK_RET, $MOCK_ERRNO);
BEGIN {
    *CORE::GLOBAL::waitpid = sub {
        $! = $MOCK_ERRNO if defined $MOCK_ERRNO;
        return $MOCK_RET;
    };
}

use WiringPi::API;   # loads WiringPi::API::BackgroundInterrupt

# Hand-built handle - running() only consults {running} and waitpid(), so no
# fork is needed. pid is irrelevant (the mock ignores it).
my $h = bless { pid => 999_999, running => 1 },
    'WiringPi::API::BackgroundInterrupt';

# waitpid == 0: child still alive -> running.
$MOCK_RET = 0; $MOCK_ERRNO = undef;
ok($h->running, 'running() true when waitpid reports the child still alive');

# waitpid == -1 / EINTR: interrupted, not exited -> must stay running.
$MOCK_RET = -1; $MOCK_ERRNO = EINTR;
ok($h->running, 'running() stays true on -1/EINTR (interrupted, not exited)');
ok($h->running, 'running() not latched stopped by a second EINTR');

# waitpid == -1 / ECHILD: child already gone -> stopped.
$MOCK_RET = -1; $MOCK_ERRNO = ECHILD;
ok(! $h->running, 'running() false on -1/ECHILD (child already reaped/gone)');

# Once it has latched stopped, running() short-circuits (no waitpid call).
$MOCK_RET = 0; $MOCK_ERRNO = undef;
ok(! $h->running, 'running() stays false after latching stopped');

# A positive reap also means gone (fresh handle).
my $h2 = bless { pid => 999_998, running => 1 },
    'WiringPi::API::BackgroundInterrupt';
$MOCK_RET = 999_998; $MOCK_ERRNO = undef;
ok(! $h2->running, 'running() false on a positive reap (child exited)');

done_testing();
