package XS::libunievent;
use XS::Loader;

use Net::SockAddr;
use XS::libuv;
use XS::libcares;

our $VERSION = '1.0.3';

XS::Loader::load_noboot();

1;
