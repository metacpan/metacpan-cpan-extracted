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

my $program_info = $client->info({
    area    => 130,
    service => 'g1',
    id      => '2014020334199',
});

warn Dumper($program_info);
