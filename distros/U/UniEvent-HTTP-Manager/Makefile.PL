use strict;
use XS::Install;

my %params = (
    NAME          => 'UniEvent::HTTP::Manager',
    CPLUS         => 14,
    BIN_DEPS      => [qw/UniEvent::HTTP XLog/],
    SRC           => ['src xs'],
    INC           => '-Isrc',
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CCFLAGS       => '-Wall -Wextra',
    test          => {
        SRC                  => 't',
        RECURSIVE_TEST_FILES => 1,
        BIN_DEPS             => 'Test::Catch',
    },
);

write_makefile(%params);
