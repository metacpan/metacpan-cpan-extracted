package WebService::Toggl::API::Tag;

use WebService::Toggl::Role::Item as => 'JsonItem';

use Moo;
with 'WebService::Toggl::Role::API';
use namespace::clean;

with JsonItem(
    bools    => [ qw()       ],
    strings  => [ qw(name)   ],
    integers => [ qw(id wid) ],
);


sub api_path { 'tags' }
sub api_id   { shift->id }



1;
__END__
