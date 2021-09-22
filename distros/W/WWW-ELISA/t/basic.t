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
can_ok $api, "create_notepad";
can_ok $api, "create_basket";

done_testing;
