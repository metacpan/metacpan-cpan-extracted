#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../lib";
use WWW::NHKProgram::API;

my $client = WWW::NHKProgram::API->new(
    api_key => '__YOUR_API_KEY__',
);

my $program_list = $client->list({
    area    => 130,
    service => 'g1',
    date    => '2014-02-02',
});

warn Dumper($program_list);
