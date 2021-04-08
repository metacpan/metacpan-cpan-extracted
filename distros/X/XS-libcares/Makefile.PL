use strict;
use XS::Install;
use Alien::cmake3;
use Env qw/@PATH/;

my $cmake_c_flags = '';
$cmake_c_flags .= ' -DCHAR_BIT=8' if $^O eq 'openbsd';

my %params = (
    NAME               => 'XS::libcares',
    CONFIGURE_REQUIRES => {'Alien::cmake3' => 0},
    BIN_SHARE => 1,
    CLIB => {
        CMAKE_TARGET => 'c-ares',
        CMAKE_OPTIONS => qq{-DCARES_STATIC=ON -DCARES_STATIC_PIC=ON -DCARES_SHARED=OFF -DCARES_BUILD_TOOLS=OFF -DCMAKE_C_FLAGS="$cmake_c_flags" -DCMAKE_INSTALL_LIBDIR=lib},
        DIR       => 'clib',
        FILE      => 'lib/libcares.a',
    },
);

write_makefile(%params);
