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

is_connected ();

sub is_connected {
    if (!$ua->is_online) {
        plan skip_all=> "SKIPPED no internet connection found" ;
        return 0;
    }
    return 1;
}

eval {
    print "#################XML test##############\n";
    ok ($valid_xml->validate(($api_xml->get_woeid({search => 'Palo Alto, CA, US'}))) , "woeid city name all") if(is_connected());
    ok ($valid_xml->validate(($api_xml->get_woeid({search => 'Palo Alto, CA, US','only' => 1}))) , "woeid city name only") if(is_connected());
};

if ($@) {
    diag ("SKIPPING test encountered problem with internet ");
}

done_testing();