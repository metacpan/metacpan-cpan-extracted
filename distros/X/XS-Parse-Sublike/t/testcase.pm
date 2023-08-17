package testcase;

use v5.14;
use warnings;

use lib "t/blib", "t/blib/arch";

use XS::Parse::Sublike;

sub import
{
   shift;
   require XSLoader;
   XSLoader::load( $_[0], $XS::Parse::Sublike::VERSION );
}

0x55AA;
