use strict;
use XS::Install;

my %params = (
    NAME          => 'XS::libpanda::backtrace',
    CPLUS         => 14,
    BIN_DEPS      => ['XS::libpanda', 'XS::libdwarf'],
    CLIB          => {
        CMAKE_TARGET => 'panda-backtrace',
        FILE         => 'libpanda-backtrace.a',
        DIR          => 'libpanda-backtrace',
    },
    BIN_SHARE     => 1,
    test          => {
        BIN_DEPS => 'Test::Catch',
        OPTIMIZE => '-g',
        CLIB     => {
            CMAKE_TARGET => 'panda-backtrace-tests',
            FILE => 'libpanda-backtrace-tests.a',
            DIR  => 'libpanda-backtrace',
        },
        RECURSIVE_TEST_FILES => 1,
    },
    CONFIGURE_REQUIRES => {'Alien::cmake3' => 0},
);

write_makefile(%params);
