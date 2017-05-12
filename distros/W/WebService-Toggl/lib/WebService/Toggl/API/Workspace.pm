package WebService::Toggl::API::Workspace;

use WebService::Toggl::Role::Item as => 'JsonItem';

use Moo;
with 'WebService::Toggl::Role::API';
use namespace::clean;

with JsonItem(
    bools => [ qw(
        admin only_admins_may_create_projects
        only_admins_see_billable_rates
        only_admins_see_team_dashboard
        premium projects_billable_by_default
    ) ],

    strings => [ qw(
        api_token default_currency ical_url logo_url name
    ) ],

    integers => [ qw(id rounding rounding_minutes) ],
    floats   => [ qw(default_hourly_rate) ],
    timestamps => [ qw(at) ],
);

sub api_path { 'workspaces' }
sub api_id   { shift->id }

sub summary_report {
    my $self = shift;
    return $self->new_report(
        '::Summary', {workspace_id => $self->id, %{ $_[0] },}
    );
}

sub users {
    my ($self) = @_;
    my $res = $self->api_get($self->my_url . '/users');
    $self->new_set_from_raw('::Users', $res->data);
}

sub clients {
    my ($self) = @_;
    my $response = $self->api_get($self->my_url . '/clients');
    return $self->new_set_from_raw('::Clients', $response->data);
}

# requires: admin
# params:
#   active: possible values true/false/both
#   actual_hours: true|false
#   only_templates: true|false
sub projects {
    my ($self) = @_;
    my $response = $self->api_get($self->my_url . '/projects');
    return $self->new_set_from_raw('::Projects', $response->data);
}

# requires: admin
# params:
#   active: possible values true/false/both
sub tasks {
    my ($self) = @_;
    my $response = $self->api_get($self->my_url . '/tasks');
    return $self->new_set_from_raw('::Tasks', $response->data);
}

sub tags {
    my ($self) = @_;
    my $response = $self->api_get($self->my_url . '/tags');
    return $self->new_set_from_raw('::Tags', $response->data);
}

sub workspace_users {
    my ($self) = @_;
    my $res = $self->api_get($self->my_url . '/workspace_users');
    $self->new_set_from_raw('::WorkspaceUsers', $res->data);
}


1;
__END__
{
   "data" : {
      "admin" : false,
      "api_token" : "a7ca77c9e1b3ea3dc8123075cbb0fae9",
      "at" : "2014-05-22T13:38:33+00:00",
      "default_currency" : "USD",
      "ical_url" : "/ical/workspace_user/c7cbada99f8abf4b4d815912ab960519",
      "id" : 252748,
      "logo_url" : "https://assets.toggl.com/logos/252748/1130762d267c58b1d62b85c9ca641a4b.jpg",
      "name" : "HemoShear workspace",
      "only_admins_may_create_projects" : true,
      "only_admins_see_billable_rates" : true,
      "only_admins_see_team_dashboard" : false,
      "premium" : true,
      "projects_billable_by_default" : true,
      "rounding" : 1
      "rounding_minutes" : 1,
   }
}
