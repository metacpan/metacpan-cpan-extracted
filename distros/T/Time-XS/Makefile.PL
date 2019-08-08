use strict;
use Config;
use XS::Install;

my $ivbits = $Config{ivsize}*8;

write_makefile(
    NAME      => 'Time::XS',
    PREREQ_PM => {'Export::XS' => 0},
    CPLUS     => 11,
    SRC       => 'src',
    INC       => '-Isrc',
    TYPEMAPS  => "typemap$ivbits",
    PAYLOAD   => {'zoneinfo' => ''},
    BIN_DEPS  => 'XS::Framework',
    BIN_SHARE => {
        INCLUDE  => {'src' => '/'},
        TYPEMAPS => {"typemap$ivbits" => ''},
    },
    CCFLAGS   => '-Wall -Wextra',
    test      => {
        SRC                  => 't',
        BIN_DEPS             => 'Test::Catch',
        RECURSIVE_TEST_FILES => 1,
    },
);
