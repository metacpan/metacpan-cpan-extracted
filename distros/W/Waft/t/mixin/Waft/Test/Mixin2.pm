package Waft::Test::Mixin2;

use constant allow_template_file_exts => qw( .pm );
use strict;
use vars qw( $VERSION );
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

$VERSION = '1.0';

sub mixin1 { 2 }

sub mixin2 { 2 }

1;
