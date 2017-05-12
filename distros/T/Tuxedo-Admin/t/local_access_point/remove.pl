#!/usr/bin/env perl

use lib '/home/keith/perl/TuxedoAdmin/lib';

use Tuxedo::Admin;

$admin = new Tuxedo::Admin;

$local_access_point = $admin->local_access_point('LOCAL2');
if ($local_access_point->exists())
{
  $local_access_point->remove();
}
else
{
  print STDERR "Does not exist!\n";
}

$admin->print_status();

