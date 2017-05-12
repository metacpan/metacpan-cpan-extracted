package WebService::Toggl::API::Workspaces;

use Moo;
with 'WebService::Toggl::Role::API', 'WebService::Toggl::Role::Set';
use namespace::clean;

sub list_of { '::Workspace' }

sub api_path { 'workspaces' }

1;
__END__
