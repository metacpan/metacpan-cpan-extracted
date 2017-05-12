package WWW::Foursquare::Config;

use strict;
use warnings;

use Exporter;
our @ISA    = 'Exporter';
our @EXPORT = qw($AUTH_CODE_ENDPOINT $ACCESS_TOKEN_ENDPOINT $API_ENDPOINT $API_VERSION);

our $AUTH_CODE_ENDPOINT    = "https://foursquare.com/oauth2/authenticate";
our $ACCESS_TOKEN_ENDPOINT = "https://foursquare.com/oauth2/access_token";
our $API_ENDPOINT          = "https://api.foursquare.com/v2/";
our $API_VERSION           = "20120915";


1;
