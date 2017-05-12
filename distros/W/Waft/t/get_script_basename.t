
use Test;
BEGIN { plan tests => 2 };

use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use English qw( -no_match_vars );
require Waft;

my $basename = Waft->get_script_basename;
ok( $basename eq 'get_script_basename.t' );

{
    local $PROGRAM_NAME = $PROGRAM_NAME . '.change_test';

    my $basename = Waft->get_script_basename;
    ok( $basename eq 'get_script_basename.t.change_test' );
}
