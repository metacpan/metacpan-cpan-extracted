package Waft::Test::Mixin1;

use strict;
use vars qw( $VERSION );
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

$VERSION = '1.0';

sub mixin1 { 1 }

1;
