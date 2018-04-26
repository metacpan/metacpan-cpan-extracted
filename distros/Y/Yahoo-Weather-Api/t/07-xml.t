#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Yahoo::Weather::Api;
use LWP::UserAgent;
use XML::Validate qw (validate);

my $valid_xml = new XML::Validate(Type => 'LibXML');
my $ua = LWP::UserAgent->new();
my $api_xml = Yahoo::Weather::Api->new({'unit' => 'F', 'format' => 'xml' });

is_connected();

sub is_connected {
    if (!$ua->is_online) {
        plan skip_all=> "SKIPPED no internet connection found" ;
        return 0;
    }
    return 1;
}

eval {
    print "#################XML test##############\n";
    ok ($valid_xml->validate(($api_xml->get_woeid({'long' => '74.932999','lat' => '31.7276',}))) , "Search geo all") if (is_connected());
    ok ($valid_xml->validate(($api_xml->get_woeid({'long' => '74.932999','lat' => '31.7276', 'only' => 1}))) , "Search geo only") if (is_connected());
};

if ($@) {
    diag ("SKIPPING test encountered problem with internet");
}

done_testing();