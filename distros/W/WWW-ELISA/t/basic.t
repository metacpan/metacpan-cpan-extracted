use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Exception;
use WWW::ELISA;

my $pkg;

BEGIN {
    $pkg = "WWW::ELISA";
    use_ok $pkg;
}
require_ok $pkg;

lives_ok {$pkg->new(callerID => "User1", secret => "s3cret")};

my $api = $pkg->new(callerID => "User1", secret => "s3cret");
can_ok $api, "push";

# my $notepad = {
#     userID      => 'me@example.com',
#     notepadName => "Wishlist_1",
#     titleList =>
#         [{title => {isbn => "9780822363804", notiz => "WWW::ELISA Test",}},
#         {title => {isbn => "9788793379312", notiz => "WWW::ELISA Test2",}}]
# };
#
# ok $api->push($notepad);

done_testing;
