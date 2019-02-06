use 5.012;
use XS::Install;

my %params = (
    NAME          => 'next::XS',
    VERSION_FROM  => 'lib/next/XS.pm',
    ABSTRACT_FROM => 'lib/next/XS.pod',
    CPLUS         => 11,
    SRC           => ['src'],
    INC           => '-Isrc',
    BIN_SHARE     => {
        CPLUS    => 11,
        INCLUDE  => {'src' => '/'},
    },
    MIN_PERL_VERSION => '5.18.0', # need GV_SUPER
    CCFLAGS          => '-Wall -Wextra -Wno-nonnull',
    test => {TESTS => 't/*.t t/perl/*.t'}
);

write_makefile(%params);
