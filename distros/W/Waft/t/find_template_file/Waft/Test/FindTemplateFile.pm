package Waft::Test::FindTemplateFile;

use base 'Waft::Test';
use strict;
use vars qw( $VERSION );
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

require Waft::Test;

$VERSION = '1.0';

1;
