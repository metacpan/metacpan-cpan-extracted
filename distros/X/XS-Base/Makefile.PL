use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'XS::Base',
    VERSION_FROM => 'lib/XS/Base.pm',
    AUTHOR       => '161263 <161263@qq.com>',
    LIBS         => ($^O =~ /MSWin32/i) ? [] : ['-lpthread'],
    DEFINE       => '',
    INC          => '',
    XS           => { 'XS/Base.xs' => 'XS/Base.c' },
    PREREQ_PM    => {
        'JSON::XS'  => 0,
        'Test::More'=> 0,
    },
    TEST_REQUIRES => {
        'Test::More'=> 0,
    },
    test         => { TESTS => 't/*.t' },
    clean        => { FILES => 'Base.c' },
);
