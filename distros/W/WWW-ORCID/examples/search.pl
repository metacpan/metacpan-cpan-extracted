#!/usr/bin/perl

use strict;
use warnings;
use WWW::ORCID;
use Getopt::Long;
use JSON qw(to_json);

my $client_id = $ENV{ORCID_CLIENT_ID};
my $client_secret = $ENV{ORCID_CLIENT_SECRET};
my $q;

GetOptions(
    "client-id=s" => \$client_id,
    "client-secret=s" => \$client_secret,
    "q=s" => \$q,
);

my $client = WWW::ORCID->new(
    version => '2.0',
    public => 1,
    sandbox => 1,
    client_id => $ENV{ORCID_CLIENT_ID},
    client_secret => $ENV{ORCID_CLIENT_SECRET},
);

print to_json($client->search(q => $q), {utf8 => 1, pretty => 1});

