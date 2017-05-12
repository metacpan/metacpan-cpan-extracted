use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/ZMQ/LibZMQ3/LibZMQ2.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/000_compile.t',
    't/001_context.t',
    't/002_socket.t',
    't/003_message.t',
    't/004_version.t',
    't/005_poll.t',
    't/006_anyevent.t',
    't/100_basic.t',
    't/101_threads.t',
    't/104_ipc.t',
    't/200_fork.t',
    't/201_thread.t',
    't/boilerplate.t',
    't/cover.sh',
    't/manifest.t',
    't/rc/.perlcriticrc',
    't/rc/.perltidyrc',
    't/rt64944.t',
    't/rt74653.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
