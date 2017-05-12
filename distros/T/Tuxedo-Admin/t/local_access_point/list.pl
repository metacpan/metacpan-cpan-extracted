#!/usr/bin/perl

use lib '/home/keith/perl/TuxedoAdmin/lib';

use Tuxedo::Admin;
use Data::Dumper;

$admin = new Tuxedo::Admin(
           'TUXDIR'    => '/opt/bea/tuxedo8.1',
           'TUXCONFIG' => '/home/keith/runtime/TUXCONFIG',
           'BDMCONFIG' => '/home/keith/runtime/BDMCONFIG'
         );
foreach $access_point ($admin->local_access_point_list())
{
  %data = $access_point->hash();
  print Dumper(\%data);
}

