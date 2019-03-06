#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use WebService::Pixela;

# All WebService::Pixela methods use this token and user name in URI, JSON, etc.
my $pixela = WebService::Pixela->new(token => "thisissecret", username => "testname");
print $pixela->username,"\n"; # testname
print $pixela->token,"\n";    # thisissecret

$pixela->user->create(); # default agreeTermsOfService and notMinor "yes"
# or...
$pixela->user->create(agree_terms_of_service => "yes", not_minor => "no"); # can input agreeTermsOfService and notMinor

$pixela->user->update("newsecret_token"); # update method require new secret token characters
print $pixela->token,"\n";

$pixela->user->delete(); # delete method not require arguments
