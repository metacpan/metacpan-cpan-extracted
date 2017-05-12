use strict;
use warnings;

use Test::More;
use Test::Exception;

use DateTime;

sub env_var { $ENV{'SLIMTIMER_' . shift} }

for ( qw( LOGIN PASSWORD API_KEY USER_ID ) ) {
    if ( !defined(env_var($_)) ) {
        plan skip_all => 'Please define environment variable "SLIMTIMER_' . $_
                       . '" required to run this test.';
    }
}

use WebService::SlimTimer;

my $st = WebService::SlimTimer->new(env_var('API_KEY'));

throws_ok { $st->login('foo', 'bar') } qr/Failed to login/,
        'Login with dummy values failed.';

ok $st->login(env_var('LOGIN'), env_var('PASSWORD')), 'Can login.';
is $st->user_id(), env_var('USER_ID'), 'Got back expected user id.';

my $initial_num_tasks = $st->list_tasks;

my $task1 = $st->create_task('First');
isa_ok $task1, 'WebService::SlimTimer::Task';

my $task2 = $st->create_task('Second');
isa_ok $task2, 'WebService::SlimTimer::Task';

my @tasks = $st->list_tasks;
is scalar @tasks, $initial_num_tasks + 2, 'Two tasks created.';

my @tasks_with_id1 = grep { $_->id == $task1->id } @tasks;
is scalar @tasks_with_id1, 1, 'Found the first task.';
is $tasks_with_id1[0]->name, 'First', 'First task has correct name.';

is $st->get_task($task2->id)->name, 'Second', 'Second task has correct name.';

my $completed_date = DateTime->now;
$st->complete_task($task1->id, $completed_date);
is $st->get_task($task1->id)->completed_on, $completed_date,
    'First task is now completed.';

my $start = DateTime->new(
        year => 2011, month => 7, day => 6,
        hour => 11, minute => 7,
        time_zone => 0
    );
my $end = DateTime->new(
        year => 2011, month => 7, day => 6,
        hour => 12, minute => 5,
        time_zone => 0
    );

my $entry = $st->create_entry($task2->id, $start, $end);
isa_ok $entry, 'WebService::SlimTimer::TimeEntry';
is $entry->duration, 3480, 'New entry duration is correct.';
is $entry->start_time->hour, 11, 'New entry start hour is correct.';

$end->set_hour(14);
$st->update_entry($entry->id, $task2->id, $start, $end);

my @entries = $st->list_entries;
is scalar @entries, 1, 'Just created entry could be retrieved.';

is $entries[0]->task_name, 'Second', 'Entry task has correct name.';
is $entries[0]->end_time->hour, $end->hour, 'End time was updated correctly.';

$st->delete_entry($entry->id);
is scalar $st->list_entries, 0, 'No entries remain.';

$st->delete_task($_->id) for @tasks;

is scalar $st->list_tasks, 0, 'No tasks remain.';

done_testing();

