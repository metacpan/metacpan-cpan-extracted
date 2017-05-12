#!/usr/bin/env perl

use Tuxedo::Admin;

$admin = new Tuxedo::Admin;
$debug = 0;

foreach $exported_resource ($admin->exported_resource_list())
{
  print "dmresourcename: ", $exported_resource->dmresourcename(), "\n"
    if $debug;
  $dmlaccesspoint = $exported_resource->dmlaccesspoint();
  print "dmlaccesspoint: $dmlaccesspoint\n"
    if $debug;
  $exported_services{$dmlaccesspoint}++;
}

foreach $laccesspoint (keys %exported_services)
{
  print $exported_services{$laccesspoint};
  print " service(s) exported from $laccesspoint\n";
}

