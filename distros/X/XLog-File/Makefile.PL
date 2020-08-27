use 5.012;
use Config;
use XS::Install;

my %params = (
    NAME      => 'XLog::File',
    CPLUS     => 14,
    SRC       => ['src'],
    INC       => '-Isrc',
    BIN_DEPS  => ['XLog', 'UniEvent'], # UniEvent for file ops and async mode
    BIN_SHARE => {INCLUDE  => {'src' => '/'}},
    CCFLAGS   => "-Wall -Wextra",
    test      => {
        SRC      => 't',
        BIN_DEPS => 'Test::Catch',
    },
);

write_makefile(%params);
