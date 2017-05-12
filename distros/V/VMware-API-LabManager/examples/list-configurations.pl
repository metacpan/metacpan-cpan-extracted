#!/usr/bin/perl -I../lib

=head1 list-configurations.pl

This example script demonstrates the Lab Manager API call 
ListConfigurations(). This call returns an array of configurations 
objects that are found.

Data::Dumper is used to print the returned array of objects.

=head3 Parameters

 --server    - LabManager server to connect to
 --username  - Username to use to perform this action with
 --password  - Password for the above username

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

print Dumper($configs);
