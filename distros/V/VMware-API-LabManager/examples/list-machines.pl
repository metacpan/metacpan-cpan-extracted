#!/usr/bin/perl -I../lib

=head1 list-machines.pl

This example script demonstrates the Lab Manager API call 
ListMachines(). This call returns an array of machine objects that are 
found within the configuration provided.

Data::Dumper is used to print the returned array of objects.

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

my $configs = $labman->ListConfigurations(1); # 1 - configs, not library entries
my $config = $configs->[0];

my $machines = $labman->ListMachines($config->{id});

print Dumper($machines);
