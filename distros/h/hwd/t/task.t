#!perl -T

use strict;
use warnings;

use Test::More tests => 100;

BEGIN {
    use_ok( 'App::HWD::Task' );
}


SIMPLE: {
    my $str = '-Create TW::DB::QuoteHead';

    my $task = App::HWD::Task->parse( $str );
    isa_ok( $task, 'App::HWD::Task' );
    is( $task->name, 'Create TW::DB::QuoteHead' );
    is( $task->level, 1 );
    is( $task->estimate, 0 );
    is( $task->id, '' );
    is( $task->date_added, '' );
    is( $task->summary, 'Create TW::DB::QuoteHead (0/0)', 'Summary');
    ok( !$task->completed, 'Not completed' );
    ok( !$task->started, 'Not started' );
    ok( !$task->is_todo );
    ok( !$task->parent );
}

WITH_ID: {
    my $str = '--API Pod Docs (#198)';

    my $task = App::HWD::Task->parse( $str );
    isa_ok( $task, 'App::HWD::Task' );
    is( $task->name, 'API Pod Docs' );
    is( $task->level, 2 );
    is( $task->estimate, 0 );
    is( $task->id, 198 );
    is( $task->date_added, '' );
    is( $task->summary, '198 - API Pod Docs (0/0)', 'Summary');
    ok( !$task->completed, 'Not completed' );
    ok( !$task->started, 'Not started' );
    ok( !$task->is_todo );
    ok( !$task->parent );
}

WITH_ESTIMATE: {
    my $str = '---API Pod Docs (4h)';

    my $task = App::HWD::Task->parse( $str );
    isa_ok( $task, 'App::HWD::Task' );
    is( $task->name, 'API Pod Docs' );
    is( $task->level, 3 );
    is( $task->estimate, 4 );
    is( $task->id, '' );
    is( $task->date_added, '' );
    is( $task->summary, 'API Pod Docs (4/0)', 'Summary');
    ok( !$task->completed, 'Not completed' );
    ok( !$task->started, 'Not started' );
    ok(  $task->is_todo );
    ok( !$task->parent );
}

WITH_ID_AND_ESTIMATE: {
    my $str = '****   Retrofitting widgets     (#142,3h)';

    my $task = App::HWD::Task->parse( $str );
    isa_ok( $task, 'App::HWD::Task' );
    is( $task->name, 'Retrofitting widgets' );
    is( $task->level, 4 );
    is( $task->estimate, 3 );
    is( $task->id, 142 );
    is( $task->date_added, '' );
    is( $task->summary, '142 - Retrofitting widgets (3/0)', 'Summary');
    ok( !$task->completed, 'Not completed' );
    ok( !$task->started, 'Not started' );
    ok(  $task->is_todo );
    ok( !$task->parent );
}

WITH_ESTIMATE_AND_ID: {
    my $str = '-Flargling dangows (540m ,#2112)';

    my $task = App::HWD::Task->parse( $str );
    isa_ok( $task, 'App::HWD::Task' );
    is( $task->name, 'Flargling dangows' );
    is( $task->level, 1 );
    is( $task->estimate, 9 );
    is( $task->id, 2112 );
    is( $task->date_added, '' );
    is( $task->summary, '2112 - Flargling dangows (9/0)', 'Summary');
    ok( !$task->completed, 'Not completed' );
    ok( !$task->started, 'Not started' );
    ok(  $task->is_todo );
    ok( !$task->parent );
}

WITH_PARENS: {
    my $str = '-Voodoo Chile (Slight Return) (#43)';
    my $task = App::HWD::Task->parse( $str );
    isa_ok( $task, 'App::HWD::Task' );
    is( $task->name, 'Voodoo Chile (Slight Return)' );
    is( $task->level, 1 );
    is( $task->estimate, 0 );
    is( $task->id, 43 );
    is( $task->date_added, '' );
    is( $task->summary, '43 - Voodoo Chile (Slight Return) (0/0)', 'Summary');
    ok( !$task->completed, 'Not completed' );
    ok( !$task->started, 'Not started' );
    ok( !$task->is_todo );
    ok( !$task->parent );
}

WITH_ID_AND_ESTIMATE_AND_DATE: {
    my $str = '----***IMPORTANT*** (#142, 3h, added 2005-12-07)';
    my $task = App::HWD::Task->parse( $str );
    isa_ok( $task, 'App::HWD::Task' );
    is( $task->name, '***IMPORTANT***' );
    is( $task->level, 4 );
    is( $task->estimate, 3 );
    is( $task->id, 142 );
    isa_ok( $task->date_added_obj, 'DateTime', 'Task date object' );
    is( $task->date_added, '2005-12-07', 'Task date string' );
    is( $task->summary, '142 - ***IMPORTANT*** (3/0)', 'Summary' );
    ok( !$task->completed, 'Not completed' );
    ok( !$task->started, 'Not started' );
    ok(  $task->is_todo );
    ok( !$task->parent );
}

WITH_FRACTIONAL_ESTIMATE: {
    my $str = '----Retrofitting widgets (.25h)';
    my $task = App::HWD::Task->parse( $str );
    isa_ok( $task, 'App::HWD::Task' );
    is( $task->name, 'Retrofitting widgets' );
    is( $task->level, 4 );
    cmp_ok( $task->estimate, '==', 0.25 );
    is( $task->id, '' );
    ok( !$task->completed, 'Not completed' );
    ok( !$task->started, 'Not started' );
    ok(  $task->is_todo );
    ok( !$task->parent );
}

WITH_DELETION: {
    my $str = '**Unnecessary task (14.5h, added 2005-11-07, deleted 2005-08-28, #2112)';
    my $task = App::HWD::Task->parse( $str );
    isa_ok( $task, 'App::HWD::Task' );
    is( $task->name, 'Unnecessary task' );
    is( $task->level, 2 );
    cmp_ok( $task->estimate, '==', 14.5 );
    is( $task->id, 2112 );
    is( $task->date_added, '2005-11-07', "Add date" );
    is( $task->date_deleted, '2005-08-28', "Delete date" );
    ok( !$task->completed, 'Not completed' );
    ok( !$task->started, 'Not started' );
    ok( !$task->is_todo );
    ok( !$task->parent );
}

INVALID: {
    my $str = 'Invalid';
    my $task = App::HWD::Task->parse( $str );
    ok( !defined( $task ), "Shouldn't parse" );
}
