use 5.012;
use Config;
use XS::Install;

my %params = (
    NAME             => 'XS::libpanda',
    CPLUS            => 14,
    SRC              => ['src'],
    INC              => '-Isrc',
    BIN_SHARE        => { INCLUDE => {'src' => '/'} },
    CCFLAGS          => '-Wall -Wextra',
    MIN_PERL_VERSION => '5.12.0',
    test             => { SRC => 't', BIN_DEPS => 'Test::Catch' },
    LIBS             => ['-lexecinfo -ldbgeng -lole32'],
);

if ($ENV{SANITIZE}) {
    ($params{CCFLAGS}||='') .= ' -fsanitize=undefined -fsanitize=address -fno-omit-frame-pointer';
    $params{LIBS}[1] .= ' -lubsan -lasan'; #sanitizer
    $params{LIBS}[0] .= ' -lubsan -lasan'; #sanitizer
}

write_makefile(%params);
