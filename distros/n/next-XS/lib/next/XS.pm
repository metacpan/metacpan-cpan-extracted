package next::XS;
use 5.012;
use mro();
use XS::Loader;

our $VERSION = '0.1.3';

{
    local $^W;
    XS::Loader::load();
}

1;
