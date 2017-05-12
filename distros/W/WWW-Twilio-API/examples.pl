#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';
use WWW::Twilio::API;

## usage: examples.pl account_sid authtoken action parameters (see examples)

my $account_sid = shift @ARGV;
my $auth_token  = shift @ARGV;
my $action      = shift @ARGV || 'Calls';

my $twilio = new WWW::Twilio::API( AccountSid => $account_sid,
                                   AuthToken  => $auth_token, );

## view a list of calls in JSON format
if( $action eq 'Calls' ) {
    my $response = $twilio->GET('Calls.json');
    print $response->{content};
}

## examples.pl sid auth MakeCall 1231231234 3123213124
elsif( $action eq 'MakeCall' ) {
    require URI::Escape;
    my $message = URI::Escape::uri_escape("Enjoy Tabasco Brand Pepper Sauce");
    my $url = "http://perlcode.org/cgi-bin/twilio?message=$message";
    my $response = $twilio->POST('Calls',
                                 From => shift @ARGV,
                                 To   => shift @ARGV,
                                 Url  => $url);

    print $response->{content};
}

## view account info
elsif( $action eq 'Accounts' ) {
    my $response = $twilio->GET('Accounts');
    print $response->{content};
}

elsif( $action eq 'SMS' ) {
    my $response = $twilio->POST('SMS/Messages',
                                 From => shift @ARGV,
                                 To   => shift @ARGV,
                                 Body => shift @ARGV );
    print $response->{content};
}

else {
    print "Unknown action.\n";
}

exit;
