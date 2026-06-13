use strict;
use warnings;

use Config;
use File::Temp qw(tempdir);
use Test::More;

use WiringPi::API ();

# Failure-path coverage for ensure_interrupt_pipe() (API.xs). The happy path
# is exercised by t/75's hardware block; these tests drive the two failure
# branches no other test reaches:
#   1. pipe() failure  - exhaust the fd table (ulimit -n) in a child perl
#   2. fcntl() failure - an LD_PRELOAD shim forces F_GETFL/F_SETFL to fail in
#      a child perl, proving the croak, the fd cleanup (no leak) and the
#      reset-to--1 (a second attempt fails identically instead of arming on
#      half-open state)

plan skip_all => 'Linux-only tests (/proc, LD_PRELOAD)' if $^O ne 'linux';

my @inc = map { "-I$_" } grep { ! ref } @INC;

# ---------------------------------------------------------------------------
# 1. pipe() failure: clamp the fd table via the shell's ulimit, fill every
# free slot, then arm - ensure_interrupt_pipe()'s pipe() gets EMFILE.
# ---------------------------------------------------------------------------

SKIP: {
    skip 'bash not available', 2 if system('bash -c true 2>/dev/null') != 0;

    my $out = do {
        open my $ph, '-|', 'bash', '-c', 'ulimit -n 64 && exec "$0" "$@"',
            $^X, @inc, '-e', _emfile_child_source()
            or die "spawn child perl: $!";
        local $/;
        <$ph>;
    };

    my %r = _kv($out // '');

    like($r{err}, qr/could not create interrupt pipe/,
        'pipe() failure (EMFILE): set_interrupt() croaks cleanly');
    is($r{fd}, -1, 'interrupt_fd() stays -1 after the failed arm');
}

# ---------------------------------------------------------------------------
# 2. fcntl() failure: build a shim that fails F_GETFL (WPI_FAIL_FCNTL=G) or
# F_SETFL (WPI_FAIL_FCNTL=S), LD_PRELOAD it into a child perl, and drive
# _arm_interrupt() into each branch. The croak never reaches wiringPiISR2,
# so no GPIO setup is needed.
# ---------------------------------------------------------------------------

SKIP: {
    my $cc = $Config{cc};
    skip 'no C compiler available', 5
        if ! $cc || system("$cc --version >/dev/null 2>&1") != 0;

    my $dir = tempdir(CLEANUP => 1);
    my $src = "$dir/fail_fcntl.c";
    my $lib = "$dir/fail_fcntl.so";

    open my $fh, '>', $src or die "open $src: $!";
    print $fh _shim_source();
    close $fh;

    skip 'could not build the LD_PRELOAD shim', 5
        if system("$cc -shared -fPIC -o '$lib' '$src' -ldl >/dev/null 2>&1") != 0;

    my $out = do {
        local $ENV{LD_PRELOAD} = $lib;
        delete local $ENV{WPI_FAIL_FCNTL};
        open my $ph, '-|', $^X, @inc, '-e', _fcntl_child_source()
            or die "spawn child perl: $!";
        local $/;
        <$ph>;
    };

    my %r = _kv($out // '');

    skip 'shim is not intercepting fcntl in the child perl', 5
        if ($r{shim} // '') eq 'inactive';

    like($r{e_getfl}, qr/could not create interrupt pipe/,
        'F_GETFL failure: _arm_interrupt() croaks');
    like($r{e_setfl}, qr/could not create interrupt pipe/,
        'F_SETFL failure: _arm_interrupt() croaks (pipe state was reset '
        . 'after the first failure)');
    is($r{mid}, $r{before}, 'no fd leaked after the F_GETFL failure');
    is($r{after}, $r{before}, 'no fd leaked after the F_SETFL failure');
    is($r{fd}, -1, 'interrupt_fd() stays -1 after the fcntl failures');
}

done_testing();

# The perl program run under a clamped ulimit. Fills every free fd slot so
# the lazy pipe() in ensure_interrupt_pipe() must fail with EMFILE.
sub _emfile_child_source {
    return <<'EOS';
use strict;
use warnings;
use WiringPi::API qw(set_interrupt interrupt_fd INT_EDGE_RISING);

# Fill every free fd slot so ensure_interrupt_pipe()'s pipe() gets EMFILE
my @fillers;
while (1) {
    open my $fh, '<', '/dev/null' or last;
    push @fillers, $fh;
}

eval { set_interrupt(5, INT_EDGE_RISING, sub {}) };
my $err = $@;
$err =~ s/[;=\n]/ /g;   # Keep the k=v report parseable

print "err=$err;fd=" . interrupt_fd();
EOS
}

# The perl program LD_PRELOADed with the shim. Probes that the shim is live,
# then drives _arm_interrupt() into the F_GETFL and F_SETFL failure branches,
# counting open fds around each to prove the error path closes the pipe.
sub _fcntl_child_source {
    return <<'EOS';
use strict;
use warnings;
use Fcntl qw(F_GETFL);
use WiringPi::API ();

my $count_fds = sub { my @f = glob "/proc/$$/fd/*"; scalar @f };

# Probe: if the shim is not intercepting this perl's fcntl(), report and bail
$ENV{WPI_FAIL_FCNTL} = 'G';
my $probe = fcntl(STDOUT, F_GETFL, 0);
delete $ENV{WPI_FAIL_FCNTL};
if (defined $probe) {
    print "shim=inactive";
    exit 0;
}

my $before = $count_fds->();

$ENV{WPI_FAIL_FCNTL} = 'G';
eval { WiringPi::API::_arm_interrupt(5, 2, 0) };
my $e_getfl = $@;
delete $ENV{WPI_FAIL_FCNTL};
my $mid = $count_fds->();

$ENV{WPI_FAIL_FCNTL} = 'S';
eval { WiringPi::API::_arm_interrupt(5, 2, 0) };
my $e_setfl = $@;
delete $ENV{WPI_FAIL_FCNTL};
my $after = $count_fds->();

s/[;=\n]/ /g for $e_getfl, $e_setfl;

print "e_getfl=$e_getfl;e_setfl=$e_setfl;"
    . "before=$before;mid=$mid;after=$after;"
    . "fd=" . WiringPi::API::interrupt_fd();
EOS
}

sub _kv {
    my $s = shift // '';
    return map { split /=/, $_, 2 } split /;/, $s;
}

# C source for the LD_PRELOAD shim. WPI_FAIL_FCNTL=G fails F_GETFL calls,
# WPI_FAIL_FCNTL=S fails F_SETFL calls; everything else passes through.
# fcntl64 is interposed too for perls built with large-file fcntl mapping.
sub _shim_source {
    return <<'EOC';
#define _GNU_SOURCE

#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdlib.h>

static int forced_failure(int cmd){
    const char *mode = getenv("WPI_FAIL_FCNTL");

    if (mode == NULL){
        return 0;
    }
    if (cmd == F_GETFL && mode[0] == 'G'){
        errno = EBADF;
        return 1;
    }
    if (cmd == F_SETFL && mode[0] == 'S'){
        errno = EINVAL;
        return 1;
    }
    return 0;
}

int fcntl(int fd, int cmd, ...){
    static int (*real)(int, int, ...) = NULL;
    va_list ap;
    long arg;

    if (forced_failure(cmd)){
        return -1;
    }
    if (real == NULL){
        real = (int (*)(int, int, ...))dlsym(RTLD_NEXT, "fcntl");
    }
    va_start(ap, cmd);
    arg = va_arg(ap, long);
    va_end(ap);
    return real(fd, cmd, arg);
}

int fcntl64(int fd, int cmd, ...){
    static int (*real)(int, int, ...) = NULL;
    va_list ap;
    long arg;

    if (forced_failure(cmd)){
        return -1;
    }
    if (real == NULL){
        real = (int (*)(int, int, ...))dlsym(RTLD_NEXT, "fcntl64");
        if (real == NULL){
            real = (int (*)(int, int, ...))dlsym(RTLD_NEXT, "fcntl");
        }
    }
    va_start(ap, cmd);
    arg = va_arg(ap, long);
    va_end(ap);
    return real(fd, cmd, arg);
}
EOC
}
