#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Yahoo::Weather::Api;
use LWP::UserAgent;
use JSON::Parse qw(valid_json);

my $ua = LWP::UserAgent->new();
my $api = Yahoo::Weather::Api->new();

is_connected();

sub is_connected {
    if (!$ua->is_online) {
        plan skip_all=> "SKIPPED no internet connection found" ;
        return 0;
    }
    return 1;
}

eval {
    print "#################JSON test##############\n";
    ok (valid_json($api->get_weather_data({search => '555512', })) , "Search zip all") if(is_connected());
    ok (valid_json($api->get_weather_data({search => '555512','only'=>1 })) , "Search zip only") if(is_connected());
};

if ($@) {
    diag ("SKIPPING test encountered problem with internet");
}

done_testing();