use strict;
use XS::Install;

my %params = (
    NAME          => 'XS::libunievent',
    CPLUS         => 14,
    BIN_DEPS      => ['Net::SockAddr', 'XS::libuv', 'XS::libcares'],
    CLIB          => {
        CMAKE_TARGET => 'unievent',
        FILE         => 'libunievent.a',
        DIR          => 'libunievent',
    },
    BIN_SHARE     => 1,
    test          => {
        BIN_DEPS => 'Test::Catch',
        CLIB => {
            CMAKE_TARGET => 'unievent-tests',
            FILE => 'libunievent-tests.a',
            DIR  => 'libunievent',
        },
        RECURSIVE_TEST_FILES => 1,
    },
    CONFIGURE_REQUIRES => {'Alien::cmake3' => 0},
);

write_makefile(%params);
