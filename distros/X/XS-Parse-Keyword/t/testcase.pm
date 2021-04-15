package testcase;

use strict;
use warnings;

use lib "t/blib", "t/blib/arch";

use XS::Parse::Keyword;

sub import
{
   shift;
   require XSLoader;
   XSLoader::load( $_[0], $XS::Parse::Keyword::VERSION );
}

0x55AA;
