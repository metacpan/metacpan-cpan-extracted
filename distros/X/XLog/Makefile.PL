use 5.012;
use XS::Install;

my %params = (
    NAME          => 'XLog',
    CPLUS         => 14,
    SRC           => 'src xs',
    INC           => '-Isrc -Ixs',
    BIN_DEPS      => ['XS::libpanda', 'XS::Framework', 'Export::XS'],
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CCFLAGS       => "-Wall -Wextra",
    TEST_REQUIRES => {'Test::Fatal' => 0},
    test          => {
        SRC => 't',
        RECURSIVE_TEST_FILES => 1,
    },
);

write_makefile(%params);
