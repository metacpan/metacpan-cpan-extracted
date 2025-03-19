package XS::libpanda::backtrace;

# load dependencies
use XS::libpanda;
use XS::libdwarf;

our $VERSION = '1.1.1';

use XS::Loader;
XS::Loader::load_noboot();

1;
