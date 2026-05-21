#!perl
use Test::More tests => 12;
use WWW::Vonage::API;
use strict;
use Data::Dumper;
 
my $api = WWW::Vonage::API->new(
        API_Key    => 'dummy_key_123',
        API_Secret => 'dummy_secret_456'
    ); 

my %test_domains = (
    1=>'api.nexmo.com/v1',
    2=>'rest.nexmo.com/v1',
    3=>'api.nexmo.com/v2',
    4=>'api.nexmo.com',
    5=>'api.nexmo.com',
    6=>'video.api.vonage.com',
    );
my %test_params =(
    1=>undef,
    2=>{API_Region=>'rest'},
    3=>{API_Version=>'v2'},
    4=>{API_Version=>'none'},
    5=>{API_Version=>'NoNe'},
    6=>{API_Region=>'video.api',API_Version=>'none',API_Domain=>'vonage.com'},
    );
foreach my $key (sort(keys(%test_domains))){
 
    my %params= (API_Key    => 'dummy_key_123',
                 API_Secret => 'dummy_secret_456');
                 
    foreach my $param (keys(%{$test_params{$key}})){
          $params{$param}=$test_params{$key}->{$param};
    }
    my $api = WWW::Vonage::API->new(
        %params
    ); 
    ok(ref($api) eq 'WWW::Vonage::API','API Created');
    my $domain = $api->_build_domain();
    ok($domain eq $test_domains{$key},"Expected: ".$test_domains{$key}." Got: ".$domain);
    
}
