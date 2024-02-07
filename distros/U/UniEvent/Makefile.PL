use strict;
use XS::Install;

my $cmake_project = "unievent";
my $cmake_tests   = "$cmake_project-tests";

my %params = (
    NAME          => 'UniEvent',
    CPLUS         => 14,
    DEFINE        => $ENV{DEBUG} ? '-DDEBUG' : '',
    TEST_REQUIRES => {'Net::SSLeay' => 0, 'Test::Exception' => 0},
    BIN_DEPS      => ['Net::SockAddr', 'XS::libuv', 'XS::libcares', 'Export::XS', 'XLog'],
    SRC           => 'src xs',
    INC           => '-Isrc',
    CCFLAGS       => '-Wall -Wextra',
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CLIB          => {
        DIR          => 'clib',
        CMAKE_TARGET => $cmake_project,
        FILE         => "lib${cmake_project}.a",
    },
    test          => {
        BIN_DEPS             => 'Test::Catch',
        SRC                  => 't',
        RECURSIVE_TEST_FILES => 1,
        CLIB                 => {
            DIR          => 'clib',
            CMAKE_OPTIONS => qq{-DUNIEVENT_TESTS=ON},
            CMAKE_TARGET => $cmake_tests,
            FILE         => "lib${cmake_tests}.a",
        },
    },
    CONFIGURE_REQUIRES => {'Alien::cmake3' => 0},
);

write_makefile(%params);
