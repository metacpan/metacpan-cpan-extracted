## ----------------------------------------------------------------------------
# t/utf8flag.t
# -----------------------------------------------------------------------------
# $Id: utf8flag.t 4504 2002-11-05 07:44:57Z hio $
# -----------------------------------------------------------------------------

use strict;
use Test;
BEGIN { plan tests => 1; }
use Unicode::Japanese;
my $string;

if( $]<5.008 )
{
  skip("your perl(v$]) maybe not support utf-8.",0,1);
}else
{
  my $CODE=<<'CODE';
	
  # ---------------------------------------------------------------------------
  # check utf-8 flag

  # h2z num
  $string = Unicode::Japanese->new("0129");
  $string->h2z();
  ok( $string->getu(), "\x{ff10}\x{ff11}\x{ff12}\x{ff19}");
  
CODE
  eval $CODE;
  $@ and die $@;
}
