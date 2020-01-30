use 5.012;
use XS::Install;

my $inst_map = {'include' => '/'};
XS::Install::_process_map($inst_map, '*.h *.hpp *.ipp');

write_makefile(
    NAME      => 'XS::libboost::mini',
    BIN_SHARE => {
        CPLUS    => 1,
        INCLUDE  => $inst_map,
    },
);
