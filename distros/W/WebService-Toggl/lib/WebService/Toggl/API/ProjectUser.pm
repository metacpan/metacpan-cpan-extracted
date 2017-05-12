package WebService::Toggl::API::ProjectUser;

use WebService::Toggl::Role::Item as => 'JsonItem';

use Moo;
with 'WebService::Toggl::Role::API';
use namespace::clean;

with JsonItem(
    bools     => [ qw(manager)     ],
    strings   => [ qw(fullname)    ],
    integers  => [ qw(pid uid wid) ],
    floats    => [ qw(rate)        ],
    timestamp => [ qw(at)          ],
);


sub api_path { 'project_users' }
sub api_id   { shift->id }


1;
__END__

{
    "data": {
        "id":4692190,
        "pid":777,
        "uid":123,
        "wid":99,
        "manager":false,
        "rate":15,
        "fullname":"John Swift",
        "at":"2013-03-05T09:21:44+00:00"
    }
}


    pid: project ID (integer, required)
    uid: user ID, who is added to the project (integer, required)
    wid: workspace ID, where the project belongs to (integer, not-required, project's workspace id is used)
    manager: admin rights for this project (boolean, default false)
    rate: hourly rate for the project user (float, not-required, only for pro workspaces) in the currency of the project's client or in workspace default currency.
    at: timestamp that is sent in the response, indicates when the project user was last updated

Workspace id (wid), project id (pid) and user id (uid) can't be changed on update.

It's possible to get user's fullname. For that you have to send the fields parameter in request with desired property name.

    fullname: full name of the user, who is added to the project
