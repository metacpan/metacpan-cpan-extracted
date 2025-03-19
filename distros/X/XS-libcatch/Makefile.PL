use XS::Install;

my %params = (
    NAME               => 'XS::libcatch',
    CONFIGURE_REQUIRES => {'Alien::cmake3' => 0},
    CPLUS              => 14,
    BIN_SHARE          => {CPLUS => 14},
    OPTIMIZE           => '-g0',
    CLIB => {
        CMAKE_TARGET  => 'Catch2',
        CMAKE_OPTIONS => "-DPROJECT_NAME=dummy",
        DIR           => 'Catch2-3.7.1',
        FILE          => 'src/libCatch2.a',
    },
);

write_makefile(%params);
