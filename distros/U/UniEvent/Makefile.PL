use strict;
use XS::Install;

my %params = (
    NAME          => 'UniEvent',
    CPLUS         => 14,
    DEFINE        => $ENV{DEBUG} ? '-DDEBUG' : '',
    TEST_REQUIRES => {'Net::SSLeay' => 0, 'Test::Exception' => 0},
    BIN_DEPS      => ['XS::libunievent', 'Export::XS'],
    SRC           => 'src xs',
    INC           => '-Isrc',
    CCFLAGS       => '-Wall -Wextra',
    OPTIMIZE      => $ENV{OPTIMIZE},
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},

    test          => {
        SRC => 't',
        RECURSIVE_TEST_FILES => 1,
    },
);

write_makefile(%params);
