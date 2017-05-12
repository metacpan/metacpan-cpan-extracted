use strict;
use Test::More 0.98;
use Test::Pretty;

use_ok $_ for qw(
    WebService::SOP::Auth::V1_1
    WebService::SOP::Auth::V1_1::Util
    WebService::SOP::Auth::V1_1::Request::GET
    WebService::SOP::Auth::V1_1::Request::POST
    WebService::SOP::Auth::V1_1::Request::POST_JSON
);

done_testing;

