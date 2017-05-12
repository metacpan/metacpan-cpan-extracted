#!/usr/bin/perl -I../lib

=head1 delete-a-vapps.pl

This example script uses the API to offer a list of vApps and to delete the 
user-selected selected vApp.

=head2 Usage

  ./list-vapps.pl --username USER --password PASS --orgname ORG --hostname HOST
  
NB: "System" is the orgname for sysadmin actions and access.

If a value is not provided in the command line, it will be asked for.

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

# Select a VM to delete

my %vapps = $vcd->list_vapps();
my @href  = keys %vapps;

die "There seem to be no vApps to delete.\n" unless scalar(@href) > 0;

print "\nSelect a vApp:\n\n";
my $c = 0;
for my $href (@href) {
    print $c++, ". $vapps{$href}\n";
}
$c--;

my $num = prompt( 'r', 'Select a vApp to delete: ', 'CTRL-C to EXIT', undef, 0, $c );

# Delete it

print "Deleting $vapps{$href[$num]}...\n";

my $ret  = $vcd->delete_vapp( $href[$num] );
my $task = $ret->{href};

my ( $val, $ref ) = $vcd->wait_on_task($task);
print "  $val\n";

print Dumper($ref) unless $val eq 'success';
