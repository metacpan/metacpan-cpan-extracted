package WebService::Toggl::API::ProjectUsers;

use Moo;
with 'WebService::Toggl::Role::API', 'WebService::Toggl::Role::Set';
use namespace::clean;

sub list_of { '::ProjectUser' }

sub api_path { 'project_users' }


1;
__END__
