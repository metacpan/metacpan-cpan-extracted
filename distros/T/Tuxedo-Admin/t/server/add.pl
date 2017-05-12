#!/usr/bin/perl

use lib '/home/keith/perl/TuxedoAdmin/lib';
use Tuxedo::Admin;

$admin = new Tuxedo::Admin(
           'TUXDIR'    => '/opt/bea/tuxedo8.1',
           'TUXCONFIG' => '/home/keith/runtime/TUXCONFIG',
           'BDMCONFIG' => '/home/keith/runtime/BDMCONFIG'
         );

$server = $admin->server('GW_GRP_1','30');
die "Server already exists\n" if $server->exists();

$server->servername('GWTDOMAIN');
$server->min('1');
$server->max('1');
$server->grace('0');
$server->maxgen('5');
$server->restart('Y');

$ok = $server->add($server);
print "Yay!\n" if $ok;

$admin->print_status();

