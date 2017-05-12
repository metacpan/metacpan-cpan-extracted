use strict;
use warnings;
use WebService::ChatWork::Message;
use Test::More tests => 1;

my $rp = WebService::ChatWork::Message->new(
    rp => (
        account_id => 3,
        room_id    => 2,
        message_id => 5,
    ),
);
is( "$rp", "[rp aid=3 to 2--5]" );
