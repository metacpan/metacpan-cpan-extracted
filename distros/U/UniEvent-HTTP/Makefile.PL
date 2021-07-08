use strict;
use XS::Install;

my $cmake_project = "unievent-http";
my $cmake_tests   = "$cmake_project-tests";

my %params = (
    NAME          => 'UniEvent::HTTP',
    CPLUS         => 14,
    BIN_DEPS      => ['UniEvent', 'Protocol::HTTP', 'UniEvent::Socks'],
    DEFINE        => $ENV{DEBUG} ? '-DDEBUG' : '',
    SRC           => ['src xs'],
    INC           => '-Isrc',
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CCFLAGS       => '-Wall -Wextra',
    PREREQ_PM     => {'XLog' => 0},
    TEST_REQUIRES => {'Test::Exception' => 0, 'Net::SSLeay' => 0,},
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
            DIR          => 'clib',
            CMAKE_TARGET => $cmake_tests,
            FILE         => "lib${cmake_tests}.a",
        },
    },
    CONFIGURE_REQUIRES => {'Alien::cmake3' => 0},
);

write_makefile(%params);
