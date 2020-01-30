use XS::Install;

my %params = (
    NAME      => 'XS::libcatch',
    BIN_SHARE => {
        CPLUS   => 11,
        INCLUDE => {'src' => '/'},
    },
);

write_makefile(%params);
