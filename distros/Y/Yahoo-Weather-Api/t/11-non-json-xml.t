#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Yahoo::Weather::Api;
use LWP::UserAgent;
use JSON qw(decode_json);
use JSON::Parse qw(valid_json);
use XML::Validate qw (validate);

my $valid_xml = new XML::Validate(Type => 'LibXML');
my $ua = LWP::UserAgent->new();

is_connected();

sub is_connected {
    if (!$ua->is_online) {
        plan skip_all=> "Problem with internet connection" ;
        return 0;
    }
    return 1;
}

eval {
    my $api = Yahoo::Weather::Api->new();
    print "########### non JSON/XML ##############\n";
    ok (valid_json($api->get_woeid_alternate({search => 'Palo Alto, CA, US'})) , "Search city name") if(is_connected());
    ok (valid_json($api->get_woeid_alternate({search => '555512'})) , "Search zip") if(is_connected());
};

if ($@) {
    diag ("SKIPPING test encountered problem with internet");
}

done_testing();