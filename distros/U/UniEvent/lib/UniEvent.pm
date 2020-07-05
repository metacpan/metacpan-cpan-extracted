package UniEvent;
use 5.012;
use Export::XS();
use Net::SockAddr();

use UE;
BEGIN { *UE:: = *UniEvent:: }

our $VERSION = '1.0.2';

XS::Loader::load();

require UniEvent::Error;

1;
