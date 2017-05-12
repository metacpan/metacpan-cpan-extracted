#!/usr/bin/perl
#
# $Id: cpe.pl 2 2014-04-08 11:42:23Z gomor $
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

my $get_cpe = $vfeed->get_cpe('CVE-2013-3930');
print Dumper($get_cpe),"\n";

$vfeed->post;
