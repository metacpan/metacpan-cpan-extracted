use 5.012;
use XS::Install;

my %params = (
    NAME             => 'next::XS',
    CPLUS            => 11,
    SRC              => ['src'],
    INC              => '-Isrc',
    MIN_PERL_VERSION => '5.18.0', # need GV_SUPER
    CCFLAGS          => '-Wall -Wextra -Wno-nonnull',
    test             => {TESTS => 't/*.t t/perl/*.t'},
    BIN_SHARE        => {INCLUDE  => {'src' => '/'}},
);

write_makefile(%params);
