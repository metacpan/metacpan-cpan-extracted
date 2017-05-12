#!/usr/bin/env perl

use lib '/home/keith/perl/TuxedoAdmin/lib';

use Tuxedo::Admin;

$admin = new Tuxedo::Admin;

foreach $service ($admin->service_list())
{
  print "Service name: ", $service->servicename(), 
        "\t", $service->srvgrp(), "\n";
}

