#!perl

use strict;
use warnings;
use Encode qw/decode_utf8/;
use WWW::NHKProgram::API::Service qw/fetch_service_id/;

use Test::More;

subtest 'Fetch service id' => sub {
    subtest 'Return ID' => sub {
        is fetch_service_id('e1'), 'e1';
        is fetch_service_id('radio'), 'radio';

        eval { fetch_service_id('perl') };
        ok $@, "Specified not exists id";
    };
    subtest 'Retrieve service id by service name' => sub {
        is fetch_service_id(decode_utf8('ＮＨＫＥテレ１')), 'e1';
        is fetch_service_id('ラジオ全て'), 'radio';

        eval { fetch_service_id('YAPC::ASIA') };
        ok $@, "Specified not exists service name";
    };
};

done_testing;
