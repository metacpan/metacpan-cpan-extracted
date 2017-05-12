package WebService::Toggl::API::Tasks;

use Moo;
with 'WebService::Toggl::Role::API', 'WebService::Toggl::Role::Set';
use namespace::clean;

sub list_of { '::Task' }

sub api_path { 'tasks' }


1;
__END__
