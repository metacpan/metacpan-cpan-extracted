package Waft::Test;

use base 'Waft';
use strict;
use vars qw( $VERSION );
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

require Waft;

$VERSION = '1.0';

1;
