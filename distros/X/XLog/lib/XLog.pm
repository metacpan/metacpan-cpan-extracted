package XLog;
use 5.012;
use Export::XS;
use XS::libpanda;
use XS::Framework;

our $VERSION = '1.1.3';

XS::Loader::load();

*warn  = *warning;
*err   = *error;
*crit  = *critical;
*emerg = *emergency;

1;
