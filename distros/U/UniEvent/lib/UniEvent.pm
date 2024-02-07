package UniEvent;
use 5.012;
use XS::libuv;
use Export::XS();
use XS::libcares;
use Net::SockAddr();

use UE;
BEGIN { *UE:: = *UniEvent:: }

our $VERSION = '1.2.13';

XS::Loader::load();

require UniEvent::Error;

1;
