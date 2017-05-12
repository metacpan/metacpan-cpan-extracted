use strict;
use warnings;
package WebService::ChatWorkApi::Response::My::Status;
use parent "WebService::ChatWorkApi::Response::My";

my @keys = qw(
    mention_num
    mention_room_num
    mytask_num
    mytask_room_num
    unread_num
    unread_room_num
);

__PACKAGE__->_gen_accessor( $_ )
    for @keys;

1;
