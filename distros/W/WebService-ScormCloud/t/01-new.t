#!perl -T

use strict;
use warnings;

use File::Spec;
use Test::More tests => 12;

use lib File::Spec->curdir;
require File::Spec->catfile('t', '_test_util.pl');

my ($AppID, $SecretKey, $ServiceURL) = getTestConfigInfo();

my $ScormCloud = new_ok(
                        'WebService::ScormCloud' => [
                                                     app_id     => $AppID,
                                                     secret_key => $SecretKey,
                                                    ]
                       );

can_ok($ScormCloud, 'app_id');
can_ok($ScormCloud, 'secret_key');
can_ok($ScormCloud, 'service_url');
can_ok($ScormCloud, 'lwp_user_agent');

is($ScormCloud->app_id,     $AppID,     '$ScormCloud->app_id');
is($ScormCloud->secret_key, $SecretKey, '$ScormCloud->secret_key');
is($ScormCloud->service_url, 'http://cloud.scorm.com/api',
    '$ScormCloud->service_url');
is($ScormCloud->lwp_user_agent->agent,
    'MyApp/1.0', '$ScormCloud->lwp_user_agent');

$ScormCloud = new_ok(
                     'WebService::ScormCloud' => [
                                         app_id         => $AppID,
                                         secret_key     => $SecretKey,
                                         service_url    => $ServiceURL,
                                         lwp_user_agent => 'TestScormCloud/1.0',
                     ]
                    );

is($ScormCloud->service_url, $ServiceURL,
    'non-default $ScormCloud->service_url');
is($ScormCloud->lwp_user_agent->agent,
    'TestScormCloud/1.0', 'non-default $ScormCloud->lwp_user_agent');

