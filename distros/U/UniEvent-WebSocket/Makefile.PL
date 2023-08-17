use 5.012;
use XS::Install;

my $cmake_project = "unievent-websocket";
my $cmake_tests   = "$cmake_project-tests";

my %params = (
    NAME          => 'UniEvent::WebSocket',
    CPLUS         => 14,
    DEFINE        => $ENV{DEBUG} ? '-DDEBUG' : '',
    BIN_DEPS      => ['UniEvent::HTTP', 'Protocol::WebSocket::Fast', 'Encode::Base2N', 'Export::XS', 'XLog'],
    SRC           => 'src xs',
    INC           => '-Isrc',
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CCFLAGS       => '-Wall -Wextra',
    PREREQ_PM     => {'XLog' => 0},
    CLIB          => {
        DIR          => 'clib',
        CMAKE_TARGET => $cmake_project,
        FILE         => "lib${cmake_project}.a",
    },
    test          => {
        SRC                  => 't',
        BIN_DEPS             => 'Test::Catch',
        RECURSIVE_TEST_FILES => 1,
        CLIB                 => {
            DIR          => 'clib',
            CMAKE_TARGET => $cmake_tests,
            CMAKE_OPTIONS => qq{-DUNIEVENT_WEBSOCKET_TESTS=ON},
            FILE         => "lib${cmake_tests}.a",
        },
    },
    CONFIGURE_REQUIRES => {'Alien::cmake3' => 0},
);

write_makefile(%params);
