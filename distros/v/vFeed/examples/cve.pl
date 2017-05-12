#!/usr/bin/perl
#
# $Id: cve.pl 6 2014-04-08 12:31:37Z gomor $
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

my $get_cve = $vfeed->get_cve('CVE-2014-02');
print Dumper($get_cve),"\n";

$vfeed->post;
