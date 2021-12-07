use XS::Install;

my %params = (
    NAME               => 'XS::libcatch',
    CONFIGURE_REQUIRES => {'Alien::cmake3' => 0},
    CPLUS              => 14,
    BIN_SHARE          => {CPLUS => 14},
    OPTIMIZE           => '-g0',
    CLIB => {
        CMAKE_TARGET => 'Catch2',
        DIR          => 'clib',
        FILE         => 'src/libCatch2.a',
    },
);

write_makefile(%params);
