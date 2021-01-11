use Test2::V0;

use exact 'lib( relative/path ../relative/path /path\ with\ spaces )', -noautoclean;

isnt( scalar( grep { $_ eq '/path with spaces' } @INC ), 0, 'path added to @INC' );

done_testing;
