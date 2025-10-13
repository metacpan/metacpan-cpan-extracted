use strict;
use warnings;

use Test::More 1;
use Test::RequiresInternet ('links.nigelhorne.com' => 'http');

BEGIN { use_ok('Test::HTTPStatus') }

http_ok('http://links.nigelhorne.com/', HTTP_OK) or diag('Live servers can be tricky. If this fails, you may want to inspect it');

done_testing();
