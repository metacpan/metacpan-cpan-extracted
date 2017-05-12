use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok( "WebService::ChatWorkApi::Data" );
    use_ok( "WebService::ChatWorkApi::Data::Me" );
    use_ok( "WebService::ChatWorkApi::Data::Message" );
    use_ok( "WebService::ChatWorkApi::Data::Room" );
}
