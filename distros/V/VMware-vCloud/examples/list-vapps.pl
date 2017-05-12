#!/usr/bin/perl -I../lib

=head1 list-vapps.pl

This example script uses the API to list all vApps that the user has ability to
 access.

=head2 Usage

  ./list-vapps.pl --username USER --password PASS --orgname ORG --hostname HOST
  
Orgname is optional. It will default to "System" if not given.

=cut

use Data::Dumper;
use Getopt::Long;
use Term::Prompt;
use VMware::vCloud;
use strict;

my ( $username, $password, $hostname, $orgname );

my $ret = GetOptions(
    'username=s' => \$username,
    'password=s' => \$password,
    'orgname=s'  => \$orgname,
    'hostname=s' => \$hostname
);

$hostname = prompt( 'x', 'Hostname of the vCloud Server:', '', '' ) unless length $hostname;
$username = prompt( 'x', 'Username:', '', undef ) unless length $username;
$password = prompt( 'p', 'Password:', '', undef ) and print "\n" unless length $password;
$orgname = prompt( 'x', 'Orgname:', '', 'System' ) unless length $orgname;

my $vcd = new VMware::vCloud( $hostname, $username, $password, $orgname, { debug => 1 } );

my %vapps = $vcd->list_vapps();

print "\n", Dumper( \%vapps );
