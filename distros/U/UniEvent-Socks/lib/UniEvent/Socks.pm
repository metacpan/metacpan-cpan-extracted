package UniEvent::Socks;
use 5.012;
use URI::XS;
use UniEvent;

our $VERSION = '1.0.0';

XS::Loader::load();

*UniEvent::Tcp::use_socks = \&use_socks;

1;
