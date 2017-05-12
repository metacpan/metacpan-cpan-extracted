#!/usr/bin/perl -I../lib

=head1 hwupgrade.pl

This example script demonstrates the Lab Manager private API call 
priv_MachineUpgradeVirtualHardware(). This upgrades the virtual hardware 
on the given machine if it is out of date. (For example, when upgrading 
from LabMan 3.x to 4.x, the virtual hardware of each VM should be 
upgraded from v4 to v7.)

=head3 Parameters

 --server    - LabManager server to connect to
 --username  - Username to use to perform this action with
 --password  - Password for the above username

 --config - Name of the configuration to upgrade virtual hardware for

=cut

use Data::Dumper;
use Getopt::Long;
use VMware::API::LabManager;
use strict;

my ( $username, $password, $server, $configname );
my $orgname   = 'Global';
my $workspace = 'Main';

my $ret = GetOptions ( 'username=s' => \$username, 'password=s' => \$password,
                       'orgname=s' => \$orgname, 'workspace=s' => \$workspace,
                       'server=s' => \$server, 'config=s' => \$configname );

die "Check the POD. This script needs command line parameters." unless
 $username and $password and $orgname and $workspace and $server;

my $labman = new VMware::API::LabManager (
  $username, $password, $server, $orgname, $workspace                        
);

my $configs = $labman->GetConfigurationByName($configname);
my $config = $configs->[0]; # GetConfigurationByName returns an array of configs
                            # that match the name. For this script, I'm only
                            # going to look at the first one.

my $machines = $labman->ListMachines($config->{id});

for my $machine (@$machines) {
  print "Upgrading hardware for $machine->{name} ($machine->{id})\n";
  my $ret = $labman->priv_MachineUpgradeVirtualHardware( $machine->{id} );
  print Dumper($ret);
}
