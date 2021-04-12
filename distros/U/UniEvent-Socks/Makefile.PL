use strict;
use XS::Install;

my $cmake_project = 'unievent-socks';
my $cmake_tests   = "$cmake_project-tests";

my %params = (
    NAME      => 'UniEvent::Socks',
    CPLUS     => 14,
    BIN_DEPS  => ['UniEvent', 'URI::XS'],
    CCFLAGS   => '-Wall -Wextra',
    BIN_SHARE => 1,
    CLIB      => {
        DIR          => 'clib',
        CMAKE_TARGET => $cmake_project,
        FILE         => "lib${cmake_project}.a",
    },
    test      => {
        BIN_DEPS => 'Test::Catch',
        CLIB     => {
            DIR          => 'clib',
            CMAKE_TARGET => "${cmake_tests}",
            FILE         => "lib${cmake_tests}.a",
        },
    },
);

write_makefile(%params);
