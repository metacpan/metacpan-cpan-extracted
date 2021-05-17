use strict;
use XS::Install;

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
    test          => {
        SRC                  => 't',
        RECURSIVE_TEST_FILES => 1,
        BIN_DEPS             => 'Test::Catch',
    },
);

write_makefile(%params);
