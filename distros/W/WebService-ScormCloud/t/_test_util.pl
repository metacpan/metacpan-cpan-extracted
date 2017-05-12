#!perl -T

use strict;
use warnings;

use File::Spec;
use WebService::ScormCloud;

require File::Spec->catfile('t', '_test_util_config.pl');

sub getScormCloudObject
{
    my ($app_id, $secret_key, $service_url, $skip_live_tests) =
      getTestConfigInfo();

    my $ScormCloud = WebService::ScormCloud->new(
        app_id              => $app_id,
        secret_key          => $secret_key,
        service_url         => $service_url,
        die_on_bad_response => 1,

        #dump_request_url    => 1,
        #dump_response_xml   => 1,
        #dump_response_data  => 1,
        #dump_api_results    => 1,
                                                );

    return ($ScormCloud, $skip_live_tests);
}

1;

