# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use lib '/home/keith/perl/TuxedoAdmin/lib';
use Test::More;

$numtests = 31;
plan tests => $numtests;

#########################


# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

local $SIG{__DIE__} = \&cleanup;

BEGIN { use_ok('Tuxedo::Admin'); }
BEGIN { use_ok('Sys::Hostname'); }

# TODO: Make this work on non-Unix systems

SKIP: {
  skip "TUXDIR not set", $numtests unless $ENV{'TUXDIR'}; 

  $tempdir = '/tmp/.TuxedoAdmin';
  -d $tempdir && cleanup();
  mkdir($tempdir)
    or skip "Can't create temporary directory: $tempdir: $!", $numtests;

  $ENV{'TUXCONFIG'} = "$tempdir/TUXCONFIG";
  $ENV{'BDMCONFIG'} = "$tempdir/BDMCONFIG";
  $ENV{'APPDIR'}    = "$tempdir/BDMCONFIG";

  -e $ENV{'TUXCONFIG'} && unlink $ENV{'TUXCONFIG'};
  -e $ENV{'BDMCONFIG'} && unlink $ENV{'BDMCONFIG'};

  $ENV{'LD_LIBRARY_PATH'} = "$ENV{'TUXDIR'}/lib:$ENV{'LD_LIBRARY_PATH'}";
  $ENV{'SHLIB_PATH'}      = "$ENV{'TUXDIR'}/lib:$ENV{'SHLIB_PATH'}";

  $hostname = Sys::Hostname::hostname();

  open(UBB,">$tempdir/ubbconfig")
    or skip  "Can't open temporary file: $tempdir/ubbconfig: $!", $numtests;
  print UBB <<"EOT";
*RESOURCES
IPCKEY          42347
MASTER          "master"
MODEL           SHM

*MACHINES
"$hostname"  LMID="master"
             TUXCONFIG="$ENV{'TUXCONFIG'}"
             TUXDIR="$ENV{'TUXDIR'}"
             APPDIR="$tempdir"

*GROUPS
"DM_GRP"  LMID="master"  GRPNO=1

*SERVERS
"DMADM"  SRVGRP="DM_GRP"  SRVID=10

*SERVICES
EOT
  close(UBB);

  $error = system("$ENV{'TUXDIR'}/bin/tmloadcf -y $tempdir/ubbconfig");
  ok( $error == 0, 'tmloadcf' );

  open(BDM,"> $tempdir/bdmconfig")
    or skip  "Can't open temporary file: $tempdir/bdmconfig: $!", $numtests;
  print BDM "*DM_RESOURCES\n";
  close(BDM);

  $error = system("$ENV{'TUXDIR'}/bin/dmloadcf -y $tempdir/bdmconfig");
  ok( $error == 0, 'dmloadcf' );

  $error = system("$ENV{'TUXDIR'}/bin/tmboot -y >/dev/null 2>&1");
  ok( $error == 0, 'tmboot' );

  my $admin = new Tuxedo::Admin;
  isa_ok( $admin, 'Tuxedo::Admin', "new admin object" );

  $group = $admin->group('GW_GRP_1');
  ok( $group, '$admin->group()' );
  $group->grpno('10');
  $group->lmid('master');
  $error = $group->add($group);
  ok( $error >= 0, '$group->add()' );

  $gwadm = $admin->server('GW_GRP_1','20');
  cmp_ok( $gwadm->servername('GWADM'), '>=', 0, 
          'set $gwadm->servername()' );
  cmp_ok( $gwadm->min('1'), '>=', 0, 
          'set $gwadm->min' );
  cmp_ok( $gwadm->max('1'), '>=', 0, 
          'set $gwadm->max' );
  cmp_ok( $gwadm->grace('0'), '>=', 0, 
          'set $gwadm->grace' );
  cmp_ok( $gwadm->maxgen('5'), '>=', 0, 
          'set $gwadm->maxgen' );
  cmp_ok( $gwadm->restart('Y'), '>=', 0, 
          'set $gwadm->restart' );
  cmp_ok( $gwadm->add(), '>=', 0, 
          '$gwadm->add' );

  $gwtdomain = $admin->server('GW_GRP_1','30');
  cmp_ok( $gwtdomain->servername('GWTDOMAIN'), '>=', 0, 
          'set $gwtdomain->servername()' );
  cmp_ok( $gwtdomain->min('1'), '>=', 0, 'set $gwtdomain->min' );
  cmp_ok( $gwtdomain->max('1'), '>=', 0, 'set $gwtdomain->max' );
  cmp_ok( $gwtdomain->grace('0'), '>=', 0, 'set $gwtdomain->grace' );
  cmp_ok( $gwtdomain->maxgen('5'), '>=', 0, 'set $gwtdomain->maxgen' );
  cmp_ok( $gwtdomain->add(), '>=', 0, '$gwtdomain->add' );

  cmp_ok( $gwtdomain->restart('Y'), '>=', 0, 'set $gwtdomain->restart' );
  cmp_ok( $gwtdomain->update(), '>=', 0, '$gwtdomain->update' );
  cmp_ok( $gwtdomain->restart(), 'eq', 'Y', 'get $gwtdomain->restart' );

  $local_access_point = $admin->local_access_point('LOCAL');
  cmp_ok( $local_access_point->dmaccesspointid('LOCAL_ID'), '>=', 0, 
          'set $local_access_point->dmaccesspointid' );
  cmp_ok( $local_access_point->dmsrvgroup('GW_GRP_1'), '>=', 0,
          'set $local_access_point->dmsrvgroup' );
  cmp_ok( $local_access_point->add, '>=', 0,
          '$local_access_point->add' );

  cmp_ok( $group->boot(), '>=', 0, '$group->boot' );
  cmp_ok( $group->shutdown(), '>=', 0, '$group->shutdown' );

  cmp_ok( $gwtdomain->remove(), '>=', 0, '$gwtdomain->remove' );
  cmp_ok( $gwadm->remove(), '>=', 0, '$gwadm->remove' );
  cmp_ok( $group->remove(), '>=', 0, '$group->remove' );

  $error = system("$ENV{'TUXDIR'}/bin/tmshutdown -y >/dev/null 2>&1");
  ok( $error == 0, 'tmshutdown' );
}

cleanup();

sub cleanup
{
  if (-d $tempdir)
  {
    #system("fuser -k $ENV{'TUXCONFIG'}");
    #system("fuser -k $ENV{'BDMCONFIG'}");
    #system("$ENV{'TUXDIR'}/bin/tmipcrm -y >/dev/null 2>&1")
    #  if (-x "$ENV{'TUXDIR'}/bin/tmipcrm");
    system("rm -rf $tempdir");
  }
}
 
