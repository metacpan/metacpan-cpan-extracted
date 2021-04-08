use strict;
use XS::Install;

my $cmake_project = 'panda-uri';
my $cmake_tests   = "$cmake_project-tests";

my %params = (
    NAME          => 'URI::XS',
    CPLUS         => 11,
    SRC           => 'src xs',
    INC           => '-Isrc',
    CCFLAGS       => '-Wall -Wextra',
    BIN_DEPS      => ['XS::Framework', 'Export::XS'],
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    TEST_REQUIRES => {'Test::Exception' => 0},
    CLIB          => {
        DIR          => 'clib',
        CMAKE_TARGET => $cmake_project,
        FILE         => "lib${cmake_project}.a",
    },
    test          => {
        RECURSIVE_TEST_FILES => 1,
        BIN_DEPS             => 'Test::Catch',
        CLIB                 => {
            DIR          => 'clib',
            CMAKE_TARGET => "${cmake_tests}",
            FILE         => "lib${cmake_tests}.a",
        },
    },
);

write_makefile(%params);
