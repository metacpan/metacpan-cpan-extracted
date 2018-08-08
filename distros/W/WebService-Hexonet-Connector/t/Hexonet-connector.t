use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::RequiresInternet ( 'coreapi.1api.net' => 80 );

our $VERSION = '1.12';

##########################
# TESTS for Connection.pm
##########################

# T1-5: test import modules
use_ok( "Scalar::Util",                             qw(blessed) );
use_ok( "WebService::Hexonet::Connector",           $VERSION );
use_ok( "WebService::Hexonet::Connector::Response", $VERSION );
use_ok( "WebService::Hexonet::Connector::Util",     $VERSION );

# T6: instantiate API Client
our $api = WebService::Hexonet::Connector::connect(
    {
        url      => 'https://coreapi.1api.net/api/call.cgi',
        entity   => '1234',
        login    => 'test.user',
        password => 'test.passw0rd'
    }
);
$api->enableDebugMode();
our $cl = blessed($api);
is(
    $cl,
    "WebService::Hexonet::Connector::Connection",
    "API Client Instance type check"
);

# T7: make API call and test Response instance
our $r = $api->call(
    {
        COMMAND => "GetUserIndex"
    }
);

$cl = blessed($r);
is(
    $cl,
    "WebService::Hexonet::Connector::Response",
    "API Response Instance type check"
);

# T8: add subuser and role - just to increase coverage, no special checks necessary
$api = WebService::Hexonet::Connector::connect(
    {
        url      => 'https://coreapi.1api.net/api/call.cgi',
        entity   => '1234',
        login    => 'test.user',
        password => 'test.passw0rd',
        user     => 'hexotestman.com',
        role     => 'testrole'
    }
);
$api->enableDebugMode();
$cl = blessed($api);
is(
    $cl,
    "WebService::Hexonet::Connector::Connection",
    "API Client Instance type check"
);

# T9: make API call and test Response instance  - just to increase coverage, no special checks necessary
$r = $api->call(
    {
        COMMAND => "GetUserIndex"
    }
);
$cl = blessed($r);
is(
    $cl,
    "WebService::Hexonet::Connector::Response",
    "API Response Instance type check"
);
$r = $api->call_raw(
    {
        COMMAND => "GetUserIndex"
    },
    {
        user => "accesscontroltest",
        role => ""
    }
);

# T10: add subuser and role - just to increase coverage, no special checks necessary
$api = WebService::Hexonet::Connector::connect(
    {
        url  => 'https://coreapi.1api.net/api/call.cgi',
        role => 'testrole'
    }
);
$api->enableDebugMode();
$cl = blessed($api);
is(
    $cl,
    "WebService::Hexonet::Connector::Connection",
    "API Client Instance type check"
);
$r = $api->call_raw(
    {
        COMMAND => "GetUserIndex"
    },
    {
        user => 'somesubsubuser'
    }
);

#######################################
# TESTS for Response.pm
#######################################
# T11 - T18: initial response class coverage test
$api = WebService::Hexonet::Connector::connect(
    {
        login    => 'test.user',
        password => 'test.password',
        entity   => '1234',
        url      => 'https://coreapi.1api.net/api/call.cgi'
    }
);
$cl = blessed($api);
$api->enableDebugMode();

#T11
is(
    $cl,
    "WebService::Hexonet::Connector::Connection",
    "API Client Instance type check"
);

#T12
$r = $api->call(
    {
        COMMAND => "GetUserIndex"
    }
);
$cl = blessed($r);
is(
    $cl,
    "WebService::Hexonet::Connector::Response",
    "API Response Instance type check"
);

#T13
ok( $r->description() eq "Authentication failed",
    "Check response description" );

#T14
ok( $r->code() eq 530, "Check response code" );

#T15
isa_ok( $r->as_list(), 'ARRAY' );

#T16
ok( ref( $r->as_list_hash() ) );

#T17
our $tmp   = $r->as_string();
our $regex = qr/code=.+description=.+/;
$tmp =~ /$regex/;
ok($tmp);

#T18
ok( !$r->is_success() );

# T19 - T20 constructor branch tests
#T19
dies_ok {
    WebService::Hexonet::Connector::Response->new($api);
}
'Unsupported Class';

#T20
$r  = WebService::Hexonet::Connector::Response->new( $r->as_list_hash() );
$cl = blessed($r);
is(
    $cl,
    "WebService::Hexonet::Connector::Response",
    "API Response Instance type check"
);

#T21 - T43 check list response
$api = WebService::Hexonet::Connector::connect(
    {
        login    => "test.user",
        password => "test.passw0rd",
        url      => "https://coreapi.1api.net/api/call.cgi",
        entity   => "1234"
    }
);
$api->enableDebugMode();
$r = $api->call(
    {
        COMMAND => "QueryDomainList",
        VERSION => 2,
        NOTOTAL => 1,    # TOTAL to have value from total to equal to count
        LIMIT   => 10,
        FIRST   => 0
    }
);
$cl = blessed($r);
is(
    $cl,
    "WebService::Hexonet::Connector::Response",
    "API Response Instance type check"
);
ok( $r->description() eq "Command completed successfully" );
ok( $r->code() eq 200 );
ok( ref( $r->properties() ) );
ok( !$r->property("DOMAIN") );
isa_ok( $r->property("OBJECTID"), 'ARRAY' );
ok( $r->is_success() );
ok( !$r->is_tmp_error() );
isa_ok( $r->columns(), 'ARRAY' );
ok( $r->first() eq 0 );
ok( $r->last() eq 9 );
ok( $r->count() eq 10 );
ok( $r->limit() eq 10 );
ok( $r->total() eq 10 );
ok( $r->pages() eq 1 );
ok( $r->page() eq 1 );
ok( !$r->prevpage() );
ok( !$r->nextpage() );
ok( !$r->prevpagefirst() );
ok( !$r->nextpagefirst() );
ok( $r->lastpagefirst() eq 0 );    #should be 9?
$tmp = $r->runtime();
ok( $tmp || !$tmp );
$tmp = $r->queuetime();
ok( $tmp || !$tmp );

#######################################
# TESTS for Util.pm
#######################################
#T44
$api = WebService::Hexonet::Connector::connect(
    {
        login    => "test.user",
        password => "test.passw0rd",
        url      => "https://coreapi.1api.net/api/call.cgi",
        entity   => "1234"
    }
);
$api->enableDebugMode();
$r = $api->call(
    {
        COMMAND => "QueryDomainPendingDeleteList",
        ZONE    => [ "COM", "NET" ],
        LIMIT   => 10,
        FIRST   => 20
    }
);
ok( $r->code() eq 200 );

#T45
our $uxorg = 1531479459;
our $ts    = WebService::Hexonet::Connector::Util::sqltime($uxorg);
ok( $ts eq "2018-07-13 10:57:39", $ts );    # should be 12:57:39!

#T46
our $ux = WebService::Hexonet::Connector::Util::timesql($ts);
ok( $ux eq $uxorg );

#T47
our $enc = WebService::Hexonet::Connector::Util::url_encode("+");
ok( $enc eq "%2B" );

#T48
our $dec = WebService::Hexonet::Connector::Util::url_decode($enc);
ok( $dec eq "+" );

#T49
our $key = "das stinkt zum Himmel";
$enc = WebService::Hexonet::Connector::Util::base64_encode($key);
ok( $enc eq "ZGFzIHN0aW5rdCB6dW0gSGltbWVs" );

#T50
$dec = WebService::Hexonet::Connector::Util::base64_decode($enc);
ok( $dec eq $key );

done_testing();
