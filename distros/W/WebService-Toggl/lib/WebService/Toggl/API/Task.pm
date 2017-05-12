package WebService::Toggl::API::Task;

use WebService::Toggl::Role::Item as => 'JsonItem';

use Moo;
with 'WebService::Toggl::Role::API';
use namespace::clean;

with JsonItem(
    bools      => [ qw(active) ],
    strings    => [ qw(name)   ],
    integers   => [ qw(pid wid uid estimated_seconds tracked_seconds) ],
    timestamps => [ qw(at)     ],
    floats     => [ qw()       ],
);


sub api_path { 'tasks' }
sub api_id   { shift->id }



1;
__END__


Tasks are available only for pro workspaces.

Task has the following properties

    name: The name of the task (string, required, unique in project)
    pid: project ID for the task (integer, required)
    wid: workspace ID, where the task will be saved (integer, project's workspace id is used when not supplied)
    uid: user ID, to whom the task is assigned to (integer, not required)
    estimated_seconds: estimated duration of task in seconds (integer, not required)
    active: whether the task is done or not (boolean, by default true)
    at: timestamp that is sent in the response for PUT, indicates the time task was last updated
    tracked_seconds: total time tracked (in seconds) for the task

Workspace id (wid) and project id (pid) can't be changed on update.
