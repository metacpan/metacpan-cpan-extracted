use strict;
use warnings;
use Test::More skip_all => 'Site24x7 account required';
use WebService::Site24x7;
use DateTime;

my $res;
my $site24x7 = WebService::Site24x7->new(
    auth_token        => $ENV{WEBSERVICE_SITE24X7_AUTH_TOKEN},
    user_agent_header => 'boop',
);

note "monitors";
$res = $site24x7->monitors->list;
is $res->{message}, "success", "message: success";
is $res->{code}, 0, "code: 0";
ok scalar @{ $res->{data} } >= 1, "found at least one monitor";
my $monitor_id = $res->{data}->[0]->{monitor_id};

note "current_status";
$res = $site24x7->current_status;
is $res->{message}, "success", "message: success";
is $res->{code}, 0, "code: 0";
ok $res->{data}->{monitor_groups},                    "found monitor_groups";
ok $res->{data}->{monitors},                          "found monitors";
ok $res->{data}->{monitors}->[0]->{last_polled_time}, "found monitors->last_polled_time";
ok $res->{data}->{monitors}->[0]->{locations},        "found monitors->locations";

note "current_status of a monitor";
$res = $site24x7->current_status(monitor_id => $monitor_id);
is $res->{message}, "success", "message: success";
is $res->{code}, 0, "code: 0";
ok $res->{data}->{name},             "found name";
ok $res->{data}->{last_polled_time}, "found last_polled_time";
ok $res->{data}->{locations},        "found locations";

note "location_profiles";
$res = $site24x7->location_profiles->list;
is $res->{message}, "success", "message: success";
is $res->{code}, 0, "code: 0";
ok scalar @{ $res->{data} } >= 1, "found at least one monitor";

note "location_template";
$res = $site24x7->location_template;
is $res->{message}, "success", "message: success";
is $res->{code}, 0, "code: 0";
ok $res->{data}->{locations}, "found locations";

note "log_reports";
# time zone must match the one set in the website's preferences
my $date = DateTime->now(time_zone => 'America/New_York');
$res = $site24x7->reports->log_reports($monitor_id, date => $date->ymd);
is $res->{message}, "success",              "message: success";
is $res->{code},    0,                      "code: 0";
ok $res->{data}->{headers},                 "found headers";
ok $res->{data}->{report},                  "found report";
ok scalar @{ $res->{data}->{report} } >= 1, "found at least one result";

note "performance reports";
my $monitors = $site24x7->monitors->list->{data};
my ($monitor) = grep { $_->{type} =~ /HOMEPAGE/ } @$monitors;
$res = $site24x7->reports->performance($monitor->{monitor_id},
    locations => 1,
    granularity => 5,
    period => 8,
);
is $res->{message}, "success", "message: success";
is $res->{code},    0,         "code: 0";
ok $res->{data}->{chart_data}, "found chart_data";
ok $res->{data}->{info},       "found info"; 
ok $res->{data}->{table_data}, "found table dasta"; 

done_testing;
