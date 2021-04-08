use XS::Install;

my %params = (
    NAME      => 'XS::libcatch',
    BIN_SHARE => {
        CPLUS   => 11,
        INCLUDE => {'clib/single_include' => '/'},
    },
);

write_makefile(%params);
