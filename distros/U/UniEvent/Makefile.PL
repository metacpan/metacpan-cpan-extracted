use strict;
use XS::Install;

my $add_inc = '';
if ($^O eq 'darwin') {
    $add_inc = '-I/usr/local/opt/openssl/include';
}

my %params = (
    NAME          => 'UniEvent',
    CPLUS         => 11,
    CPLUS         => 14,
    DEFINE        => $ENV{DEBUG} ? '-DDEBUG' : '',
    TEST_REQUIRES => {'Net::SSLeay' => 0, 'Test::Exception' => 0},
    BIN_DEPS      => ['Net::SockAddr', 'Export::XS', 'XS::libuv', 'XS::libcares'],
    SRC           => 'src xs backend-uv',
    INC           => "-Isrc -Ibackend-uv/include $add_inc",
    LIBS          => ['-lpthread -lssl -lcrypto -lrt', '-lpthread -lssl -lcrypto'],
    CCFLAGS       => '-Wall -Wextra',
    OPTIMIZE      => $ENV{OPTIMIZE},
    BIN_SHARE     => {
        INC     => $add_inc,
        INCLUDE => {
            'src'                => '/',
            'backend-uv/include' => '/',
        },
    },
    test => {
        SRC                  => 't',
        RECURSIVE_TEST_FILES => 1,
        BIN_DEPS             => 'Test::Catch',
    },
);

if ($ENV{PANDA_SANITIZE}) {
    $params{LIBS}[0] .= ' -lubsan -lasan';
    ($params{CCFLAGS}||='') .= ' -fsanitize=undefined -fsanitize=address -fno-omit-frame-pointer';
}

write_makefile(%params);
