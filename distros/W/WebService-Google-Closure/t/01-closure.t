#!/usr/bin/perl

BEGIN {
    # setup mockable support
    $ENV{ LWP_UA_MOCK }         ||= 'playback';
    $ENV{ LWP_UA_MOCK_FILE }    ||= 't/mock/01-closure';
}

use lib "t/lib";
use t::WebService::Google::Closure;
Test::Class->runtests;
