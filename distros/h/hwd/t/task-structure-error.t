#!perl -Tw

use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
    use_ok( 'App::HWD' );
}

my ($tasks,$work,$tasks_by_id,$errors) = App::HWD::get_tasks_and_work( *DATA );
is( @$errors, 2, "Two errors returned" );
like( $_, qr/has no parent/, "Correct text" ) for @$errors;

__DATA__
-Phase A
---Prep
---Start branch (#100, 2h)
--LISTUTILS package
---need cannedListCoMedia (#101, 3h)
    If we don't write this, everything fails.
---Remove ltype dependencies (#102, 3h)
---Update tests (#103, 3h)
