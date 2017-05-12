package WebService::Toggl::API::Clients;

use Moo;
with 'WebService::Toggl::Role::API', 'WebService::Toggl::Role::Set';
use namespace::clean;

sub list_of { '::Client' }

sub api_path { 'clients' }


1;
__END__
