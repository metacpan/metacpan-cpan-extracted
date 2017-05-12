package WebService::Toggl::API::TimeEntries;

use Moo;
with 'WebService::Toggl::Role::API', 'WebService::Toggl::Role::Set';
use namespace::clean;

sub list_of { '::TimeEntry' }

sub api_path { 'time_entries' }

1;
__END__
