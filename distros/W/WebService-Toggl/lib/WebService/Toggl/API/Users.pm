package WebService::Toggl::API::Users;

use Moo;
with 'WebService::Toggl::Role::API', 'WebService::Toggl::Role::Set';
use namespace::clean;

sub list_of { '::User' }

sub api_path { 'users' }

1;
__END__
