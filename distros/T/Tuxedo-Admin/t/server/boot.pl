#!/usr/bin/perl

use lib '/home/keith/perl/TuxedoAdmin/lib';
use Tuxedo::Admin;

$admin = new Tuxedo::Admin(
           'TUXDIR'    => '/opt/bea/tuxedo8.1',
           'TUXCONFIG' => '/home/keith/runtime/TUXCONFIG',
           'BDMCONFIG' => '/home/keith/runtime/BDMCONFIG'
         );

$server = $admin->server('GW_GRP_1','30');
if ($server->exists())
{
  if ($server->state() ne 'ACTIVE')
  {
    $server->boot();
    $admin->print_status();
  }
  else
  {
    print "Server already booted.\n";
  }
}
else
{
  print "Server does not exist.\n";
}

