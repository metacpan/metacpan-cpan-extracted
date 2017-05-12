#!/usr/bin/perl

use lib '/home/keith/perl/TuxedoAdmin/lib';
use Tuxedo::Admin;
use Tuxedo::Admin::Server;
use Data::Dumper;

$admin = new Tuxedo::Admin(
           'TUXDIR'    => '/opt/bea/tuxedo8.1',
           'TUXCONFIG' => '/home/keith/runtime/TUXCONFIG',
           'BDMCONFIG' => '/home/keith/runtime/BDMCONFIG'
         );

$server = $admin->server('GW_GRP_1', '30');
die "Can't find server\n" unless $server->exists();
print Dumper($server->hash());

if ($server->grace() == 0)
{
  $server->grace('86400');
}
else
{
  $server->grace('0');
}

$server->update();

$admin->print_status(*STDERR);

