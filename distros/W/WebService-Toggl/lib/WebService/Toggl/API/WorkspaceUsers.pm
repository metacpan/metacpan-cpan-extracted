package WebService::Toggl::API::WorkspaceUsers;

use Moo;
with 'WebService::Toggl::Role::API', 'WebService::Toggl::Role::Set';
use namespace::clean;

sub list_of { '::WorkspaceUser' }

sub api_path { 'workspaces/' . shift->workspace_id . '/users' }


1;
__END__
