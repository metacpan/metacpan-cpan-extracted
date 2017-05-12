#!/usr/bin/perl -I../lib

=head1 create-vapp-from-template.pl

This example script uses the API to compose a template to a vApp

=head2 Usage

  ./create-vapp-from-template.pl --username USER --password PASS --orgname ORG --hostname HOST

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

# Select an Org

my %orgs = $vcd->list_orgs();
my $orgid = &select_one( "Select the Org you wish to create a vApp in:", \%orgs, 1 );

# Select a VDC

my %vdcs = $vcd->list_vdcs($orgname);
my $vdcid = &select_one( "Select the Virtual Data Center you wish to create a vApp in:", \%vdcs );

# Select a template

my %templates = $vcd->list_templates();
my $templateid = &select_one( "Select the Template you wish to put in your vApp:", \%templates );

# Select network

my %networks = $vcd->list_networks($vdcid);
my $networkid = &select_one( "Select the Network you wish the template to use in:", \%networks, 1 );

# Build the vApp

my $name = 'Example vApp';
my ( $task_href, $ret ) = $vcd->create_vapp_from_template( $name, $vdcid, $templateid, $networkid );

# Wait on task to complete

my ( $status, $task ) = $vcd->wait_on_task($task_href);

print "\nSTATUS: $status\n";
print "\n" . Dumper($task) if $status eq 'error';

#### Subroutines

# This subroutine quickly handles user input to select items from a hash

sub select_one {
    my $message = shift @_;

    my %items = %{ shift @_ };
    my @items =
        sort { lc( $items{$a} ) cmp lc( $items{$b} ) } keys %items;   # Put the names in alpha order

    my $reverse = shift @_;

    my $line = '=' x 80;
    my $i    = 1;

    print "\n$line\n";

    for my $item (@items) {
        my $label = $reverse ? $item : $items{$item};
        print "   $i. $label\n";
        $i++;
    }

    my $id = prompt( 'n', $message, '', undef );
    $id -= 1;

    return $reverse ? $items{ $items[$id] } : $items[$id];
}
