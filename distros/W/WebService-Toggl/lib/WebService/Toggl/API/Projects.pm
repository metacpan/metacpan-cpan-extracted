package WebService::Toggl::API::Projects;

use Moo;
with 'WebService::Toggl::Role::API', 'WebService::Toggl::Role::Set';
use namespace::clean;

sub list_of { '::Project' }

sub api_path { 'projects' }

1;
__END__
