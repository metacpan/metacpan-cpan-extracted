use strict;
use XS::Install;

my %params = (
    NAME      => 'XS::libuv',
    CLIB      => {
        CMAKE_TARGET => 'uv_a',
        FILE         => 'libuv_a.a',
        DIR          => 'libuv'
    },
);

write_makefile(%params);
