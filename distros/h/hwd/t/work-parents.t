#!perl -Tw

use strict;
use warnings;

use Test::More tests => 19;

BEGIN {
    use_ok( 'App::HWD' );
}

my ($tasks,$work,$tasks_by_id,$errors) = App::HWD::get_tasks_and_work( *DATA );

is_deeply( $errors, [], "No errors" );

FIRST: {
    my $task = $tasks->[0];
    is( $task->name, 'Phase A', 'First task name' );
    is( $task->parent, undef, 'First has no parent' );
}

SECOND: {
    my $task = $tasks->[1];
    is( $task->name, 'Prep', 'Second task name' );
    is( $task->parent->name, 'Phase A', "Second task's parent's name" );
    is( $task->parent->parent, undef, 'Second has no grandparent' );
    like( ($task->notes)[0], qr/customers.+properly/ );
    is( $task->work, 3, "Three work items done" );
}

THIRD: {
    my $task = $tasks->[2];
    is( $task->name, 'NLW changes', 'Third name' );
    is_deeply( [$task->notes], [], 'No notes' );
    is( $task->work, 0, "Three work items done" );
}

FOURTH: {
    my $task = $tasks->[3];
    is( $task->name, 'NLW::MissileTracking', 'Fourth name' );
    is( scalar $task->notes, 1, 'Only one line of notes' );
    like( ($task->notes)[0], qr/YAGNI/, 'First line of notes' );
    is( $task->work, 4, "Four work items done" );
}

FIFTH: {
    my $task = $tasks->[4];
    is( $task->name, 'NLW::Transmute::Gold2Lead', 'Fifth name' );
    is_deeply( [$task->notes], [], 'No notes' );
    is( $task->work, 1, "One work item done" );
}

__DATA__
-Phase A

--Prep (#401)
    Need to make sure customers are getting handled properly.

alester 2006-01-29  ^ 1.5   # Initial sniffing
alester 2006-02-05  ^ 3 X 
--NLW changes
# Another comment
---NLW::MissileTracking (3h)
    This will probably a YAGNI.
autarch 2006-02-11  ^ 5

# Comment in the middle of nowhere
autarch 2006-02-12  ^ 2 X   # Finished
autarch 2006-02-13  401 1.5 # I want to track 401 here for some reason
autarch 2006-02-14  ^ 3     # Bug fixes
autarch 2006-02-15  ^ 3 X   # Finished the fixes
---NLW::Transmute::Gold2Lead
alester 2006-01-15  ^ 3
