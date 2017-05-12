#!perl -Tw

use strict;
use warnings;

use Test::More tests => 24;

BEGIN {
    use_ok( 'App::HWD' );
}

my ($tasks,$work,$tasks_by_id,$errors) = App::HWD::get_tasks_and_work( *DATA );

is( @$errors, 0, "No errors" );

my $first = $tasks->[0];
is( $first->name, 'Phase A', 'First task name' );
is( $first->parent, undef, 'First has no parent' );

my $second = $tasks->[1];
is( $second->name, 'Prep', 'Second task name' );
is( $second->parent->name, 'Phase A', "Second task's parent's name" );
is( $second->parent->parent, undef, 'Second has no grandparent' );

my $third = $tasks->[2];
is( $third->name, 'Start branch', 'Third task name' );
is( $third->parent->name, 'Prep', "Third task's parent's name" );
is( $third->parent->parent->name, 'Phase A', "Third task's grandparent's name" );
is( $third->parent->parent->parent, undef, 'Third has no grandparent' );

my $fourth = $tasks->[3];
is( $fourth->name, 'LISTUTILS package', 'Fourth task name' );
is( $fourth->parent->name, 'Phase A', "Fourth task's parent's name" );
is( $fourth->parent->parent, undef, 'Fourth has no grandparent' );

my $last = $tasks->[-1];
is( $last->name, 'List Profile - which stats to display', 'Last name' );
is( $last->parent->name, 'Templates', "Last's parent's name" );
is( $last->parent->parent->name, 'Phase A', "Last task's grandparent's name" );
is( $last->parent->parent->parent, undef, 'Last has no grandparent' );
is( $last->where, 'line 15 of DATA' );

cmp_ok( scalar $first->children,    '==', 3 );
cmp_ok( scalar $second->children,   '==', 1 );
cmp_ok( scalar $third->children,    '==', 0 );
cmp_ok( scalar $fourth->children,   '==', 3 );
cmp_ok( scalar $last->children,     '==', 0 );


__DATA__
-Phase A
--Prep
---Start branch (#100, 2h)
    Blah blah blah
--LISTUTILS package
---need cannedListCoMedia (#101, 3h)
    If we don't write this, everything fails.
---Remove ltype dependencies (#102, 3h)
---Update tests (#103, 3h)

# Note: We can't start this phase until everything above is done, but we
# don't want to make it a subtask.
--Templates
---Remove "Book/AV" choice from "create list" (#104, 1h)
---List Profile - which stats to display (#105, 2h)
