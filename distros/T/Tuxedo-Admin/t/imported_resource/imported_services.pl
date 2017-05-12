#!/usr/bin/env perl

use Tuxedo::Admin;

$admin = new Tuxedo::Admin;
$debug = 0;

foreach $imported_resource ($admin->imported_resource_list())
{
  print "dmresourcename: ", $imported_resource->dmresourcename(), "\n"
    if $debug;
  $dmraccesspointlist = $imported_resource->dmraccesspointlist();
  print "dmraccesspointlist: $dmraccesspointlist\n"
    if $debug;
  $dmlaccesspoint = $imported_resource->dmlaccesspoint();
  print "dmlaccesspoint: $dmlaccesspoint\n"
    if $debug;
  @remote_access_points = split(/,/,$dmraccesspointlist);
  foreach $remote_access_point (@remote_access_points)
  {
    print "remote_access_point: $remote_access_point\n"
      if $debug;
    $local_connection{$dmlaccesspoint}{$remote_access_point}++;
  }
}

foreach $laccesspoint (keys %local_connection)
{
  foreach $raccesspoint (keys %{ $local_connection{$laccesspoint} })
  {
    print $local_connection{$laccesspoint}{$raccesspoint};
    print " service(s) imported from $raccesspoint to $laccesspoint\n";
  }
}

