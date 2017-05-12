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

print "THIS WILL DELETE EVERYTHING ON THE TARGET LAB MANAGER SERVER: $server\n\nCTRL-C to avoid this. RETURN to continue with deletion.\n";

<STDIN>;

print "NO REALLY. I MEAN IT. --> EVERYTHING <-- WILL BE DELETED.\n\nCTRL-C to avoid this. RETURN to continue with deletion.\n";

<STDIN>;

my @confs = ( $labman->ListConfigurations(1), $labman->ListConfigurations(2) );
for my $conf (@confs) {
  my $id = $conf->{id};
  my $name = $conf->{name};

  if ( $conf->{isDeployed} eq 'true' ) {  
    print "Undeploying config: $name ($id)\n";
    my $ret = $labman->ConfigurationUndeploy($id);
    warn $ret if $ret;
  }

  print "Deleting config: $name ($id)\n";
  my $ret = $labman->ConfigurationDelete($id);
  warn $ret if $ret;
}

my @templates = ( $labman->priv_ListTemplates() );
for my $temp (@templates) {
  next if $temp eq ''; # WTF?
  my $id = $temp->{id};
  my $name = $temp->{name};

  next if $name =~ /^VMwareLM-ServiceVM/; # Internal labman machine

  if ( $temp->{isDeployed} eq 'true' ) {  
    print "Undeploying template: $name ($id)\n";
    my $ret = $labman->priv_TemplatePerformAction($id,2);
    warn $ret if $ret;
  }

  print "Deleting template: $name ($id)\n";
  my $ret = $labman->priv_TemplatePerformAction($id,3);
  warn $ret if $ret;
}
