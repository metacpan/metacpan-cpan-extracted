package testcase;

use v5.14;
use warnings;

use lib "t/blib", "t/blib/arch";

use XS::Parse::Keyword;

sub import
{
   shift;
   require XSLoader;
   XSLoader::load( $_[0], $XS::Parse::Keyword::VERSION );
}

sub unimport
{
   die "testcase cannot be unimported";
}

0x55AA;
