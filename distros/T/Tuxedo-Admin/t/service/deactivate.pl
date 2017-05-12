#!/usr/bin/env perl

use lib '/home/keith/perl/TuxedoAdmin/lib';
use Tuxedo::Admin;

$admin = new Tuxedo::Admin;

$service = $admin->service('DMADMIN', 'DM_GRP');

$service->srvid('10');
$service->rqaddr('00001.00010');

$service->suspend() && $service->deactivate();

$admin->print_status();

