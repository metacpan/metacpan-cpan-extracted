package WebService::Toggl::API::WorkspaceUser;

use WebService::Toggl::Role::Item as => 'JsonItem';

use Moo;
with 'WebService::Toggl::Role::API';
use namespace::clean;

with JsonItem(
    bools    => [ qw( admin active) ],
    strings  => [ qw( email at name invite_url ) ],
    integers => [ qw( id uid wid ) ]
);

sub api_path { 'workspace_users' }
sub api_id   { shift->id }


1;
__END__
    {
        "id":3123855,
        "uid":35224123,
        "wid":777,
        "admin":false,
        "active":false,
        "email":"John@toggl.com",
        "at":"2013-05-17T16:50:36+03:00",
        "name":"John Swift",
        "invite_url":"https://toggl.com/user/accept_invitation?code=fb3ad3db5dasd123c2b529e3a519826"
    },
