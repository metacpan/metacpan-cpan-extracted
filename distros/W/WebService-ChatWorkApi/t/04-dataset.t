use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok( "WebService::ChatWorkApi::DataSet" );
    use_ok( "WebService::ChatWorkApi::DataSet::Me" );
    use_ok( "WebService::ChatWorkApi::DataSet::Message" );
    use_ok( "WebService::ChatWorkApi::DataSet::Room" );
}
