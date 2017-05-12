#!/usr/bin/perl

use lib '/home/keith/perl/TuxedoAdmin/lib';
use Tuxedo::Admin;

$admin = new Tuxedo::Admin;

$local_access_point = $admin->local_access_point('LOCAL2');
unless ($local_access_point->exists())
{
  $local_access_point->dmaccesspointid('LOCAL2_ID');
  $local_access_point->dmsrvgroup('GW_GRP_2');
  $error = $local_access_point->add();
  die $admin->status() if ($error < 0);
  print $admin->status(), "\n";

  $tdomain1 = $admin->tdomain('LOCAL2', 'mail:8765');
  $error = $tdomain1->add();
  die $admin->status() if ($error < 0);
  print $admin->status(), "\n";

  $tdomain2 = $admin->tdomain('LOCAL2', 'mail:8766');
  $error = $tdomain2->add();
  die $admin->status() if ($error < 0);
  print $admin->status(), "\n";
}
else
{
  print STDERR "Already exists!\n";
}

