use strict;
use XS::Install;

my %libs = (
    MSWin32 => '-liphlpapi -lpsapi -luserenv',
);

my %params = (
    NAME => 'XS::libuv',
    CLIB => {
        CMAKE_TARGET => 'uv_a',
        FILE         => 'libuv_a.a',
        DIR          => 'libuv'
    },
    LINK               => $libs{$^O},
    CONFIGURE_REQUIRES => {'Alien::cmake3' => 0},
    BIN_SHARE          => 1,
);

write_makefile(%params);
