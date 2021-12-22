use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok('URL::XS'); };

can_ok('URL::XS', 'parse_url', 'split_url_path', 'parse_url_query');
ok $URL::XS::VERSION, 'has a VERSION package variable';

done_testing;
