#!/usr/bin/perl
#
# $Id: latest.pl 2 2014-04-08 11:42:23Z gomor $
#
use strict;
use warnings;

use vFeed::DB;
use vFeed::Log;
use Data::Dumper;

my $db = shift or die("Give DB file\n");

my $log = vFeed::Log->new;

my $vfeed = vFeed::DB->new(
   log => $log,
   file => $db,
);
$vfeed->init;

my $db_version = $vfeed->db_version;
print "[+] vFeed db_version: $db_version\n\n";

my $latest_cve = $vfeed->latest_cve;
print Dumper($latest_cve),"\n";

$vfeed->post;
