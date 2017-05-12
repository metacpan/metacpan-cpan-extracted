#!/usr/bin/perl

use lib '/home/keith/perl/TuxedoAdmin/lib';
use Tuxedo::Admin;
use Tuxedo::Admin::Server;

$admin = new Tuxedo::Admin(
           'TUXDIR'    => '/opt/bea/tuxedo8.1',
           'TUXCONFIG' => '/home/keith/runtime/TUXCONFIG',
           'BDMCONFIG' => '/home/keith/runtime/BDMCONFIG'
         );

$server = $admin->server('GW_GRP_1','30');
die "no server found\n" unless $server->exists();

die "Can't remove a server while it is booted.\n"
  unless ($server->state() eq 'INACTIVE');

$server->remove();
$admin->print_status();

