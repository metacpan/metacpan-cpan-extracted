use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok( "WebService::ChatWorkApi::Response" );
    use_ok( "WebService::ChatWorkApi::Response::Me" );
    use_ok( "WebService::ChatWorkApi::Response::My" );
    use_ok( "WebService::ChatWorkApi::Response::My::Status" );
}
