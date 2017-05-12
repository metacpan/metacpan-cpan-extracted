#!/usr/bin/perl

use strict;
use warnings;

use ZipTie::Client;

die("You must specify at least one device!\n") unless (@ARGV);

my $devices = join(',', @ARGV);

my $client = ZipTie::Client->new(username => 'admin', password => 'password', host => 'localhost:8080', );

my %scheme = (key => 'ipResolutionScheme', value => 'ipCsv');
my %data = (key => 'ipResolutionData', value => $devices);

my %param_map = (entry => [\%scheme, \%data]);

my %job = (description => 'Perl initiated configuration backup.',
           jobGroup => '_interactive',
           jobName => 'Perl Backup ' . time(),
           jobType => 'Backup Configuration',
           jobParameters => \%param_map);

my $execution = $client->scheduler()->runNow(jobData => \%job);

print("Scheduled backup with execution ID: $execution->{id} \n");

