package WebService::Toggl::API::TimeEntry;

use Sub::Quote qw(quote_sub);
use WebService::Toggl::Role::Item as => 'JsonItem';

use Moo;
with 'WebService::Toggl::Role::API';
use namespace::clean;

with JsonItem(
    bools      => [ qw(billable duronly) ],
    strings    => [ qw(start stop description created_with ) ],
    integers   => [ qw(id wid pid tid duration) ],
    timestamps => [ qw(at) ],
    floats     => [ qw() ],
);

# ArrayRef
has tags => (is => 'ro', lazy => 1, builder => quote_sub(qq| \$_[0]->raw->{$_} |));


sub api_path { 'time_entries' }
sub api_id   { shift->id }



1;
__END__
{
   "data" : {
      "id":436694100,
      "wid":777,
      "pid":193791,
      "tid":13350500,
      "billable":false,
      "start":"2013-02-27T01:24:00+00:00",
      "stop":"2013-02-27T07:24:00+00:00",
      "duration":21600,
      "description":"Some serious work",
      "tags":["billed"],
      "at":"2013-02-27T13:49:18+00:00"
   }
}


The requests are scoped with the user whose API token is used. Only his/her time entries are updated, retrieved and created.

Time entry has the following properties

    description: (string, strongly suggested to be used)
    wid: workspace ID (integer, required if pid or tid not supplied)
    pid: project ID (integer, not required)
    tid: task ID (integer, not required)
    billable: (boolean, not required, default false, available for pro workspaces)
    start: time entry start time (string, required, ISO 8601 date and time)
    stop: time entry stop time (string, not required, ISO 8601 date and time)
    duration: time entry duration in seconds. If the time entry is currently running, the duration attribute contains a negative value, denoting the start of the time entry in seconds since epoch (Jan 1 1970). The correct duration can be calculated as current_time + duration, where current_time is the current time in seconds since epoch. (integer, required)
    created_with: the name of your client app (string, required)
    tags: a list of tag names (array of strings, not required)
    duronly: should Toggl show the start and stop time of this time entry? (boolean, not required)
    at: timestamp that is sent in the response, indicates the time item was last updated
