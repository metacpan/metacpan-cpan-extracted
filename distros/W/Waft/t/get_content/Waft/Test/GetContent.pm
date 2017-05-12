package Waft::Test::GetContent;

use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use base qw( Waft );
require Waft;

use vars qw( $VERSION );
$VERSION = '1.0';

1;
