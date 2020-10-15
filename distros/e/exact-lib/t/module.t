use Test::Most;

BEGIN {
    use_ok( 'exact', 'lib', 'noautoclean' );
    use_ok( 'exact', 'lib( relative/path ../relative/path /path\ with\ spaces )', 'noautoclean' );
}

isnt( scalar( grep { $_ eq '/path with spaces' } @INC ), 0, 'path added to @INC' );

done_testing();
