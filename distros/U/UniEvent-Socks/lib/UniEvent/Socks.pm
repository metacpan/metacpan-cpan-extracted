package UniEvent::Socks;
use 5.012;
use URI::XS;
use UniEvent;

our $VERSION = '0.1.1';

XS::Loader::load();

*UniEvent::Tcp::use_socks = \&use_socks;

1;
