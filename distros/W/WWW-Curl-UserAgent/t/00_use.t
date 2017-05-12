use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 3;

BEGIN {
    use_ok('WWW::Curl::UserAgent');
    use_ok('WWW::Curl::UserAgent::Request');
    use_ok('WWW::Curl::UserAgent::Handler');
}
