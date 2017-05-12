package WebService::Toggl::API::Project;

use WebService::Toggl::Role::Item as => 'JsonItem';

use Moo;
with 'WebService::Toggl::Role::API';
use namespace::clean;

with JsonItem(
    bools      => [ qw(active is_private template billable auto_estimates) ],
    strings    => [ qw(name) ],
    integers   => [ qw(id wid cid template_id color estimated_hours) ],
    timestamps => [ qw(at created_at) ],
    floats     => [ qw(rate) ],
);


sub api_path { 'projects' }
sub api_id   { shift->id }


sub project_users {
    my ($self) = @_;
    my $res = $self->api_get($self->my_url . '/project_users');
    return $self->new_set_from_raw('::ProjectUsers', $res->data);
}

sub tasks {
    my ($self) = @_;
    my $res = $self->api_get($self->my_url . '/tasks');
    return $self->new_set_from_raw('::Tasks', $res->data);
}


1;
__END__

{
    "data": {
        "id":193838628,
        "wid":777,
        "cid":123397,
        "name":"An awesome project",
        "billable":false,
        "is_private":true,
        "active":true,
        "at":"2013-03-06T12:15:37+00:00",
        "template":true
        "color": "5"
    }
}


    name: The name of the project (string, required, unique for client and workspace)
    wid: workspace ID, where the project will be saved (integer, required)
    cid: client ID (integer, not required)
    active: whether the project is archived or not (boolean, by default true)
    is_private: whether project is accessible for only project users or for all workspace users (boolean, default true)
    template: whether the project can be used as a template (boolean, not required)
    template_id: id of the template project used on current project's creation
    billable: whether the project is billable or not (boolean, default true, available only for pro workspaces)
    auto_estimates: whether the estimated hours is calculated based on task estimations or is fixed manually (boolean, default false, not required, premium functionality)
    estimated_hours: if auto_estimates is true then the sum of task estimations is returned, otherwise user inserted hours (integer, not required, premium functionality)
    at: timestamp that is sent in the response for PUT, indicates the time task was last updated (read-only)
    color: id of the color selected for the project
    rate: hourly rate of the project (float, not required, premium functionality)
    created_at: timestamp indicating when the project was created (UTC time), read-only

