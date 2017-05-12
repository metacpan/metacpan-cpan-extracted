#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok( 'Workflow::Lite' );
  use_ok( 'Workflow::Lite::Registry' );
  use_ok( 'Workflow::Lite::Role::Workflow' );
}

diag( "Testing Workflow::Lite $Workflow::Lite::VERSION, Perl $], $^X" );

done_testing;
