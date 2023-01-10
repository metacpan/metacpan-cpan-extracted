use strict;
use Test::More 0.98;

use_ok $_ for qw(
    WebService::DS::SOP::Auth::V1_1
    WebService::DS::SOP::Auth::V1_1::Util
    WebService::DS::SOP::Auth::V1_1::Request::GET
    WebService::DS::SOP::Auth::V1_1::Request::POST
    WebService::DS::SOP::Auth::V1_1::Request::POST_JSON
);

done_testing;

