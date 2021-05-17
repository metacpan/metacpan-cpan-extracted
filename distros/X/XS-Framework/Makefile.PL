use 5.018;
use Config;
use XS::Install;

my $ccflags = $^O eq 'MSWin32' ? '-Wno-unused-parameter' : '';
$ccflags .= ' -fmax-errors=5' if $ENV{DEV};
my $ivbits = $Config{ivsize}*8;

# MINIMUM PERL VERSION:
# 5.22 for op_sibling_splice() required for callback dispatcher's add_weak()
# 5.20 for working COP hints (for COP hints API)
# 5.18 for GV_SUPER method call

my %params = (
    NAME      => 'XS::Framework',
    CPLUS     => 14,
    SRC       => ['src'],
    INC       => '-Isrc',
    TYPEMAPS  => ['typemap', "typemap$ivbits"],
    BIN_DEPS  => ['XS::libpanda', 'next::XS'],
    PARSE_XS  => 'XS::Framework::ParseXS',
    BIN_SHARE => {
        INCLUDE  => {'src' => '/'},
        PARSE_XS => 'XS::Framework::ParseXS',
        TYPEMAPS => {
            'typemap'        => '',
            "typemap$ivbits" => '',
        },
    },
    MIN_PERL_VERSION => '5.22.0',
    CCFLAGS          => "-Wall -Wextra $ccflags",
    TEST_REQUIRES    => {'Test::Exception' => 0},
    test             => {
        SRC                  => 't',
        BIN_DEPS             => 'Test::Catch',
        RECURSIVE_TEST_FILES => 1,
    },
);

write_makefile(%params);
