#!perl

use strict;
use warnings;
use Encode qw/decode_utf8/;
use WWW::NHKProgram::API::Area qw/fetch_area_id/;

use Test::More;

subtest 'Fetch area id' => sub {
    subtest 'Return ID' => sub {
        is fetch_area_id('040'), '040';
        is fetch_area_id('260'), '260';
    };
    subtest 'Retrieve area id by area name' => sub {
        is fetch_area_id(decode_utf8('仙台')), '040';
        is fetch_area_id('京都'), '260';

        eval { fetch_area_id('ラピュタ') };
        ok $@, 'died by illegal city';
    };
};

done_testing;
