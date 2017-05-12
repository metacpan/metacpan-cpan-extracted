#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use WWW::Jirafe;
use JSON;
use Data::Dumper;

die unless $ENV{JIRAFE_SITE_ID} and $ENV{JIRAFE_ACCESS_TOKEN};

my $jirafe = WWW::Jirafe->new(
    site_id => $ENV{JIRAFE_SITE_ID},
    access_token => $ENV{JIRAFE_ACCESS_TOKEN},
);

my $params = decode_json('{
    "id": "1234abc",
    "active_flag": true,
    "change_date": "2013-06-17T15:15:53.000Z",
    "create_date": "2013-06-17T15:15:53.000Z",
    "email": "john.doe@gmail.com",
    "first_name": "John",
    "last_name": "Doe",
    "name": "John Doe"
}');

my $res = $jirafe->customer($params);
print Dumper(\$res);