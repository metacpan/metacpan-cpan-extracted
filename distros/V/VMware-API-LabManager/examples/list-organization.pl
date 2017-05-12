#!/usr/bin/perl -I../lib

use Data::Dumper;
use Getopt::Long;
use VMware::API::LabManager;
use strict;

my ( $username, $password, $server);
my $orgname   = 'Global';
my $workspace = 'Main';

my $ret = GetOptions ( 'username=s' => \$username, 'password=s' => \$password,
                       'orgname=s' => \$orgname, 'workspace=s' => \$workspace,
                       'server=s' => \$server );

die "Check the POD. This script needs command line parameters." unless
 $username and $password and $orgname and $workspace and $server;

my $labman = new VMware::API::LabManager (
  $username, $password, $server, $orgname, $workspace                        
);

my $orgs = $labman->priv_GetOrganizations();

for my $org (@$orgs) {
  my $org_id = $org->{Id};
  my $org_name = $org->{Name};
  print "ORG: $org_name ($org_id)\n";

  my $wss = $labman->priv_GetOrganizationWorkspaces($org_id);
  $wss = [ $wss ] if ref $wss eq 'HASH'; # Single workspace condition

  for my $ws (@$wss) {
    my $ws_id = $ws->{Id};
    my $ws_name = $ws->{Name};
    print "  WS: $ws_name ($ws_id)\n";

    if ( $ws->{Configurations} and $ws->{Configurations}->{Configuration} ) {
      my $confs = $ws->{Configurations}->{Configuration};
      $confs = [ $confs ] if ref $confs eq 'HASH'; # Single configuration condition
      for my $conf (@$confs) {
        my $conf_id = $conf->{id};
        my $conf_name = $conf->{name};
        print "    CONF: $conf_name ($conf_id)\n";
      }
    }
  }
  print "\n";
}
