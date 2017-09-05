package Test2::Require::Win;

use strict;
use warnings;
use base qw( Test2::Require );

sub skip
{
  return $^O !~ /^(cygwin|MSWin32)$/
    ? 'Test only runs on cygwin or MSWin32'
    : return ();
}

1;
