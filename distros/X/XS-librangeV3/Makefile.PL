use 5.012;
use XS::Install;

write_makefile(
    NAME      => 'XS::librangeV3',
    BIN_SHARE => {
    	CPLUS   => 11,
        INCLUDE => {'clib/include' => '/'},
    },
);
