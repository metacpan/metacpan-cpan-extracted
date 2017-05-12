#!/usr/bin/env perl

use lib '/home/keith/perl/TuxedoAdmin/lib';

use Tuxedo::Admin;

$admin = new Tuxedo::Admin;

$\ = "\n";

foreach $group ($admin->group_list())
{
  print "Group name: ", $group->srvgrp();
  print "Group number: ", $group->grpno();
}

