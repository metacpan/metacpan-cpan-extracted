#!/usr/public/bin/perl -w

use strict;
use JSON;
use JSON::WebToken;
use LWP::UserAgent;
use HTML::Entities;

use Data::Dumper;
use Config::JSON;
use feature 'say';
# Originally based on Gist - https://gist.github.com/gsainio/6322375


## See also 
# https://developers.google.com/admin-sdk/reports/v1/guides/delegation

## NB service account domain-wide delegation can take up to 24 hrs as per https://github.com/googleapis/google-api-php-client/issues/1379


my $fname = '~/google/computerproscomau-99cb495aa2ff.json';
$fname = '/Users/peter/google/computerproscomau-99cb495aa2ff.json';
my $tokensfile = Config::JSON->new( $fname );
#print Dumper $tokensfile;

#say $tokensfile->get('private_key');



#exit;


my $private_key_string = q[-----BEGIN PRIVATE KEY-----
PEM CONTENTS GO HERE
-----END PRIVATE KEY-----
];

$private_key_string = $tokensfile->get('private_key');

my $time = time;

# https://developers.google.com/accounts/docs/OAuth2ServiceAccount

# https://developers.google.com/identity/protocols/OAuth2ServiceAccount
my $jwt = JSON::WebToken->encode({
                                  # your service account id here
                                  #iss => 'webservice-google-client-teste@computerproscomau.iam.gserviceaccount.com',
                                  iss => '110051964826033416319',
                                 #scope => 'https://www.googleapis.com/auth/admin.directory.user',
                                 scope => 'email profile https://www.googleapis.com/auth/plus.profile.emails.read https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/contacts.readonly https://mail.google.com https://www.googleapis.com/auth/plus.business.manage',
                                  aud => 'https://www.googleapis.com/oauth2/v3/token',
                                  exp => $time + 3600,
                                  iat => $time,
                                  # To access the google admin sdk with a service account
                                  # the service account must act on behalf of an account
                                  # that has admin privileges on the domain
                                  # Otherwise the token will be returned but API calls
                                  # will generate a 403
                                  # prn =>  'admin@your-domain.com',
                                  # prn =>  'peter@shotgundriver.com',
                                  #prn => 'webservice-google-client-teste@computerproscomau.iam.gserviceaccount.com',
                                  #prn=>'computerproscomau'
                                 }, $private_key_string, 'RS256', {typ => 'JWT'}
                                );

# Now post it to google
my $ua = LWP::UserAgent->new(); #'https://www.googleapis.com/oauth2/v3/token
my $response = $ua->post( 'https://www.googleapis.com/oauth2/v3/token',
                         {grant_type => encode_entities('urn:ietf:params:oauth:grant-type:jwt-bearer'),
                          assertion => $jwt});

unless($response->is_success()) {
    die($response->code, "\n", $response->content, "\n");
}

say "got this far";
my $data = decode_json($response->content);


say $data->{access_token};
# The token is added to the HTTP authentication header as a bearer
my $api_ua = LWP::UserAgent->new();
$api_ua->default_header(Authorization => 'Bearer ' . $data->{access_token});

# get the details for a user
#my $api_response = $api_ua->get('https://www.googleapis.com/admin/directory/v1/users/');# .encode_entities('peter@shogundriver.com'));
#my $api_response = $api_ua->get('https://www.googleapis.com/gmail/v1/users/me/messages?q=newer_than:1d;to:peter@shotgundriver.com' ); #.encode_entities('peter@shogundriver.com'));
#my $api_response = $api_ua->get('https://www.googleapis.com/gmail/v1/users/peter@shotgundriver.com/messages');
my $api_response = $api_ua->get('https://www.googleapis.com/gmail/v1/users/peter@shotgundriver.com/profile');
if($api_response->is_success) {
    my $api_data = decode_json($api_response->content);
    use Data::Dumper;
    print Dumper($api_data);
} else {
    print "Error:\n";
    print "Code was ", $api_response->code, "\n";
    print "Msg: ", $api_response->message, "\n";
    print $api_response->content, "\n";
    die;
}
