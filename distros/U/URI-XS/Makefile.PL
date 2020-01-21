use strict;
use XS::Install;

my %params = (
    NAME          => 'URI::XS',
    CPLUS         => 11,
    SRC           => 'src',
    INC           => '-Isrc -I/usr/local/include',
    BIN_DEPS      => ['XS::Framework', 'Export::XS'],
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CCFLAGS       => '-Wall -Wextra -Wno-implicit-fallthrough -Wno-unused-const-variable',
    TEST_REQUIRES => {'Test::Exception' => 0},
    test          => {
        RECURSIVE_TEST_FILES => 1,
    },
);

if ($ENV{TEST_FULL}) {
    $params{LIBS}[0] .= ' -lubsan';
    ($params{CCFLAGS}||='') .= ' -fsanitize=undefined';
}

if ($ENV{DEV}) {
    my $postamble = '';
    my $gentype = "-G2";
    for (qw/parser.rl/) {
        my $file = "src/panda/uri/$_";
        my $cfile = $file; $cfile =~ s/\.rl/.cc/;
        $postamble .= "parser : $cfile\n\n";
        $postamble .= "$cfile : $file\n".
                      "\t ragel -C $gentype $file -o $cfile\n\n";
    }
    $params{postamble} .= $postamble;
}

write_makefile(%params);
