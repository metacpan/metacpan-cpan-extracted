#!/usr/bin/perl

use Getopt::Long;
use Tuxedo::Admin;

print STDERR <<EOT;
psr.pl - Copyright (c) 2003 Keith Burdis
All Rights Reserved.
Distributed under the same license as Perl itself.
Tuxedo is a registered trademark of BEA Systems, Inc.

EOT

$admin = new Tuxedo::Admin;

GetOptions(\%optctl, "srvgrp|g=s", "srvid|i=s", "servername|s=s");

$filter{'srvgrp'}     = $optctl{srvgrp} if exists $optctl{srvgrp};
$filter{'srvid'}      = $optctl{srvid} if exists $optctl{srvid};
$filter{'servername'} = $optctl{servername} if exists $optctl{servername};

foreach $server (reverse $admin->server_list(\%filter))
{
  next if ($server->state() eq 'INACTIVE');
  ($servername) = $server->servername() =~ m:/?([^/]+)$:;
  $groupname = $server->srvgrp();
  $groupname = $server->lmid() if ($groupname eq '');
  $current_service = $server->currservice();
  $current_service = 'IDLE'
    if (($current_service eq '') or ($current_service =~ /^\./));
  $current_service = $server->state() if ($server->state() ne 'ACTIVE');
  write;
}
print "\n";

format STDOUT_TOP =
Prog Name      Queue Name  Grp Name      ID RqDone Load Done Current Service
---------      ----------  --------      -- ------ --------- ---------------
.

format STDOUT =
@<<<<<<<<<<<<< @<<<<<<<<<< @<<<<<<<<<<<< @> @>>>>> @>>>>>>>> ( @>>>>>>>>>> )
$servername,$server->rqaddr(),$groupname,$server->srvid(),$server->totreqc(),$server->totworkl(),$current_service
.

