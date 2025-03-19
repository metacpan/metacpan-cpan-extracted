use strict;
use XS::Install;

my $cmake_project = "unievent-http-manager";
my $cmake_tests   = "$cmake_project-tests";

my %params = (
    NAME          => 'UniEvent::HTTP::Manager',
    CPLUS         => 14,
    BIN_DEPS      => [qw/UniEvent::HTTP XLog/],
    SRC           => ['src xs'],
    INC           => '-Isrc',
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CCFLAGS       => '-Wall -Wextra',
    CLIB          => {
        DIR          => 'clib',
        CMAKE_TARGET => $cmake_project,
        FILE         => "lib${cmake_project}.a",
    },
    test          => {
        SRC                  => 't',
        RECURSIVE_TEST_FILES => 1,
        BIN_DEPS             => 'Test::Catch',
        CLIB                 => {
            DIR              => 'clib',
            CMAKE_TARGET     => $cmake_tests,
            CMAKE_OPTIONS     => qq{-DUNIEVENT_HTTP_MANAGER_TESTS=ON},
            FILE             => "lib${cmake_tests}.a",
        },
    },
    CONFIGURE_REQUIRES => {'Alien::cmake3' => 0},
);

write_makefile(%params);
