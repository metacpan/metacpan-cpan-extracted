use strict;
use XS::Install;

my $libs = '';
$libs .= ' -liphlpapi -lpsapi -luserenv' if $^O eq 'MSWin32'; 

my %params = (
    NAME => 'XS::libuv',
    LIBS => $libs,
    CLIB => {
        CMAKE_TARGET => 'uv_a',
        FILE         => 'libuv_a.a',
        DIR          => 'libuv'
    },
    CONFIGURE_REQUIRES => {'Alien::cmake3' => 0},
);

write_makefile(%params);
