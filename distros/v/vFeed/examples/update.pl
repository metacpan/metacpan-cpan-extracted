#!/usr/bin/perl
#
# $Id: update.pl 5 2014-04-08 11:49:21Z gomor $
#
use strict;
use warnings;

use vFeed::DB;
use vFeed::Log;
use Data::Dumper;

my $db = shift or die("Give DB file\n");

my $log = vFeed::Log->new(
   level => 3,
);

my $vfeed = vFeed::DB->new(
   log => $log,
   file => $db,
);
$vfeed->init;

$vfeed->update;

$vfeed->post;
