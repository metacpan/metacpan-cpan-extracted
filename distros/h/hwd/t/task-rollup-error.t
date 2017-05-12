#!perl -Tw

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok( 'App::HWD' );
}

my ($tasks,$work,$tasks_by_id,$errors) = App::HWD::get_tasks_and_work( *DATA );
is( @$errors, 1 );
like( $errors->[0], qr/Task 103.+cannot have estimates/ );

__DATA__
-Phase A
--Prep (#101)
--LISTUTILS package (#107)
---need cannedListCoMedia (#102, 3h)
    If we don't write this, everything fails.
---Remove ltype dependencies (#112, 3h)
---Update tests (#103, 3h)
----Foo tests (#105, 1h)
----Bar tests (#115, 3h)
