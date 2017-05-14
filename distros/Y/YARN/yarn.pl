#!/usr/bin/perl

use strict;
use warnings;
use YARN;
use Data::Dumper;

# global variables
my $yarnHost = 'hadoop-master.aossama.com';

my $client = YARN->new( host => $yarnHost );
#print Dumper $client;

# get root queue name
my $scheduler = $client->scheduler(); print $scheduler->{'type'};
my @allQueues = $client->getAllQueues(); print Dumper @allQueues;

print $client->info('id') . "\n" . $client->metrics('availableMB') . "\n" . $client->scheduler->{'type'};

#print Dumper $client->apps();
