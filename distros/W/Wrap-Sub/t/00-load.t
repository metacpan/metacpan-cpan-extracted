#!perl
use 5.006;
use strict;
use warnings;
use Test::More;


BEGIN {
    use_ok( 'Wrap::Sub' ) || print "Bail out!\n";
    use_ok( 'Wrap::Sub::Child' ) || print "Bail out!\n";
}

diag( "Testing Wrap::Sub $Wrap::Sub::VERSION, Perl $], $^X" );

can_ok('Wrap::Sub', 'new');
can_ok('Wrap::Sub', 'wrap');
can_ok('Wrap::Sub', 'wrapped_subs');
can_ok('Wrap::Sub', 'wrapped_objects');
can_ok('Wrap::Sub', 'is_wrapped');

can_ok('Wrap::Sub::Child', 'new');
can_ok('Wrap::Sub::Child', '_wrap');
can_ok('Wrap::Sub::Child', 'unwrap');
can_ok('Wrap::Sub::Child', 'name');
can_ok('Wrap::Sub::Child', 'called_with');
can_ok('Wrap::Sub::Child', 'called');
can_ok('Wrap::Sub::Child', 'is_wrapped');
can_ok('Wrap::Sub::Child', 'pre');
can_ok('Wrap::Sub::Child', 'post');
can_ok('Wrap::Sub::Child', '_check_wrap');
can_ok('Wrap::Sub::Child', 'DESTROY');

done_testing();
