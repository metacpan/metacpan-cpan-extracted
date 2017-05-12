#!/usr/bin/perl

use strict;
use warnings;

use ZipTie::Client;

die("You must specify a CSV file\n") unless (@ARGV);

my $filename = shift(@ARGV);

my $client = ZipTie::Client->new(username => 'admin', password => 'password', host => 'localhost:8080', );

open(CSV, "<$filename") or die "CSV file could not be opened.";

my @devices;
my @failed;
while (<CSV>)
{
    chomp;

    my ($ip_address, $hostname, $adapter_id, $folder) = split(/,/);
    next unless ($ip_address =~ /^\d+/);

	my %device = (ipAddress => $ip_address, hostname => $hostname, adapterId => $adapter_id);
	push(@devices, \%device);

    if (@devices == 1000)
    {
        print "Importing 1000 devices...";
        @failed = $client->devices()->createDeviceBatched(devices => \@devices);
        print " " . (@devices - @failed) . " succeeded.\n";
        @devices = ();
    }
}

if (@devices > 0)
{
    print "Importing " . @devices . " devices...";
    @failed = $client->devices()->createDeviceBatched(devices => \@devices);
    print " " . (@devices - @failed) . " succeeded.\n";
}

close(CSV);
