use 5.012;
use Config;
use XS::Install;

my %libs = (
    MSWin32 => '-ldbgeng -lole32',
    linux   => '',
    darwin  => '',
    freebsd => '-lexecinfo',
    openbsd => '',
    default => '-lexecinfo',
);

my $cmake_project = "panda-lib";
my $cmake_tests   = "$cmake_project-tests";

my %params = (
    NAME               => 'XS::libpanda',
    CPLUS              => 14,
    LINK               => $libs{$^O} // $libs{default},
    BIN_SHARE          => 1,
    CONFIGURE_REQUIRES => {'Alien::cmake3' => 0},
    CLIB               => {
        DIR          => 'clib',
        CMAKE_TARGET => $cmake_project,
        FILE         => "lib${cmake_project}.a",
    },
    test               => {
        BIN_DEPS => 'Test::Catch',
        CLIB     => {
            DIR          => 'clib',
            CMAKE_TARGET => $cmake_tests,
            FILE         => "lib${cmake_tests}.a",
        },
        RECURSIVE_TEST_FILES => 1,
    },
);

write_makefile(%params);
