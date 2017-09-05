package Test2::Require::Not58;

use strict;
use warnings;
use base qw( Test2::Require );

sub skip
{
  return $] < 5.010
    ? 'Test only runs on Perl 5.10 or better'
    : return ();
}

1;
