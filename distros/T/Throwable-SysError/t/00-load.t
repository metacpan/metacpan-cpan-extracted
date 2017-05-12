#!perl -T

use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok( 'Throwable::SysError' );
}

diag( "Throwable::SysError $Throwable::SysError::VERSION, Perl $], $^X" );

done_testing;
