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
  my $this_orgname = $org->{Name};
  print "\nORG: $this_orgname\n";

  $labman->config( orgname => $this_orgname );

  my $templates = $labman->priv_ListTemplates();

  print Dumper($templates);
}
