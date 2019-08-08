use strict;
use XS::Install;

my %params = (
    NAME      => 'URI::XS',
    PREREQ_PM => {'Export::XS' => 0},
    CPLUS     => 11,
    SRC       => 'src',
    INC       => '-Isrc -I/usr/local/include',
    BIN_DEPS  => 'XS::Framework',
    BIN_SHARE => {INCLUDE  => {'src' => '/'}},
    CCFLAGS   => '-Wall -Wextra',
);

if ($ENV{TEST_FULL}) {
    $params{LIBS}[0] .= ' -lubsan';
    ($params{CCFLAGS}||='') .= ' -fsanitize=undefined';
}

write_makefile(%params);
