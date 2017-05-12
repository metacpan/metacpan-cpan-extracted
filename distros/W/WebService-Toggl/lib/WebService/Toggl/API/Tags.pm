package WebService::Toggl::API::Tags;

use Moo;
with 'WebService::Toggl::Role::API', 'WebService::Toggl::Role::Set';
use namespace::clean;

sub list_of { '::Tag' }

sub api_path { 'tags' }

1;
__END__
