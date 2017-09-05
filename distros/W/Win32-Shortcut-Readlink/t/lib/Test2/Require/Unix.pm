package Test2::Require::Unix;

use strict;
use warnings;
use base qw( Test2::Require );

sub skip
{
  return $^O =~ /^(MSWin32)$/
    ? 'Test does not run on MSWin32'
    : return ();
}

1;
