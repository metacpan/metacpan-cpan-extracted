#!/usr/bin/env perl

use strict;
use warnings;

use WebService::Linode;
use Data::Dumper;

my $api = WebService::Linode->new(
    apikey => 'your api key',
    fatal  => 1,
);

my $method = shift;
print Dumper ( $api->$method );
