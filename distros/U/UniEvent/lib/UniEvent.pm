package UniEvent;
use 5.012;
use Export::XS();
use XS::libunievent();

use UE;
BEGIN { *UE:: = *UniEvent:: }

our $VERSION = '1.1.2';

XS::Loader::load();

require UniEvent::Error;

1;
