#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use WebService::HabitRPG::Task;

my $task_template = {
    'history' => [
                    {
                    'value' => 1,
                    'date' => '1363704173288'
                    },
                    {
                    'value' => '1.12180193129597',
                    'date' => '1363962197256'
                    },
                    {
                    'value' => '1.06831755945709',
                    'date' => '1364317131627'
                    },
                    {
                    'value' => '1.26025870144542',
                    'date' => '1364532357911'
                    },
                    {
                    'value' => '1.15350362239235',
                    'date' => '1364772796659'
                    },
                    {
                    'value' => '1.07024823425376',
                    'date' => '1365174938958'
                    },
                    {
                    'value' => '1.521504861382',
                    'date' => '1365264792807'
                    }
                ],
    'value' => '0.760752430691001',
    'up' => 1,
    'notes' => '',
    'text' => 'Floss Teeth',
    'down' => 0,
    'id' => 'a670fc50-4e04-4b0f-9583-e4ee55fced02',
    'type' => 'habit',
    'streak' => 0
};

# Let's start with an actual task.

my $task = WebService::HabitRPG::Task->new($task_template);

isa_ok($task, 'WebService::HabitRPG::Task');
is($task->id, 'a670fc50-4e04-4b0f-9583-e4ee55fced02');
is($task->type, 'habit');
is($task->down, 0);
is($task->up, 1);

is($task->streak, 0);

{
    my $formatted = $task->format_task;

    like(   $formatted, qr/\+/,          "Task can be incremented");
    unlike( $formatted, qr/-/,           "Task can't be decremented");
    like(   $formatted, qr/Floss Teeth/, "Task name in format");
}

# Now let's try some invalid things.

eval {
    my $badtask = WebService::HabitRPG::Task->new(
        { %$task_template, type => "invalid" }
    );
};

ok($@,"Invalid type throws exception");

foreach my $attr ('text','id') {
    foreach my $invalid (undef, '') {
        eval {
            my $badtask = WebService::HabitRPG::Task->new(
                { %$task_template, $attr => $invalid }
            );
        };

        ok($@,"Invalid $attr throws exception");
    }
}

done_testing;
