use 5.018;
use Config;
use XS::Install;

my $ccflags = $^O eq 'MSWin32' ? '-Wno-unused-parameter' : '';
my $ivbits = $Config{ivsize}*8;

my %params = (
    NAME      => 'XS::Framework',
    CPLUS     => 14,
    SRC       => ['src'],
    INC       => '-Isrc',
    TYPEMAPS  => ['typemap', "typemap$ivbits"],
    BIN_DEPS  => ['CPP::panda::lib', 'next::XS'],
    PARSE_XS  => 'XS::Framework::ParseXS',
    BIN_SHARE => {
        INCLUDE  => {'src' => '/'},
        PARSE_XS => 'XS::Framework::ParseXS',
        TYPEMAPS => {
            'typemap'        => '',
            "typemap$ivbits" => '',
        },
    },
    MIN_PERL_VERSION => '5.18.0', # required for GV_SUPER
    CCFLAGS          => "-Wall -Wextra $ccflags",
    TEST_REQUIRES    => {'Test::Exception' => 0},
    test             => {
        SRC                  => 't',
        BIN_DEPS             => 'Test::Catch',
        RECURSIVE_TEST_FILES => 1,
    },
);

write_makefile(%params);
