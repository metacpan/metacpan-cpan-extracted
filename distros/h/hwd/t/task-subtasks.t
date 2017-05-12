#!perl -Tw

use strict;
use warnings;

use Test::More tests => 12;

BEGIN {
    use_ok( 'App::HWD' );
}

my ($tasks,$work,$tasks_by_id,$errors) = App::HWD::get_tasks_and_work( *DATA );

is( @$errors, 0, "No errors" );
my $top = $tasks->[0];
ok(  $top->is_todo,                     'Top task has no todo' );

    my $templates = $tasks->[1];
    ok(  $templates->is_todo,           'Templates task is not done' );

        my $third = $tasks->[2];
        ok( !$third->is_todo,           'Third task is done' );

        my $fourth = $tasks->[3];
        ok(  $fourth->is_todo,          'Fourth task is not done' );

    my $bongos = $tasks->[4];
    ok( !$bongos->is_todo,              'Bongos task has no todo' );

        my $deleted = $tasks->[5];
        ok(  $deleted->date_deleted,    'Deleted task is deleted' );
        ok( !$deleted->is_todo,         'Deleted task is not a todo' );

        my $last = $tasks->[5];
        ok( !$last->is_todo,            'Last task is closed' );

TOTAL_ESTIMATE: {
    my $estimate;
    $top->subtask_walk( sub { $estimate += shift->estimate } );
    is( $estimate, 148, "Total hours correct" );
}

UNDELETED_ESTIMATE: {
    my $estimate;
    $top->subtask_walk( sub { $estimate += $_[0]->estimate unless $_[0]->date_deleted } );
    is( $estimate, 6, "Undeleted hours correct" );
}

__DATA__
-Phase A
--Templates
---Remove "Book/AV" choice from "create list" (#104, 1h)
---List Profile - which stats to display (#105, 2h)
--Bongos
---Implement psychic DWIM interface (#100, 142h, deleted 2005-09-30)
---need cannedListCoMedia (#101, 3h)
    If we don't write this, everything fails.


Mike    10/6    104 1.5
Mike    10/7    104 1.5 X
Mike    10/7    105 1
Mike    10/7    101 1   X
