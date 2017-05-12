#!/usr/bin/perl -I../lib

=head1 org_get.pl

This example script shows how to successfully retrieve data on a specific
organization from VCD via the API.

=head2 Usage

  ./org_get.pl --username USER --password PASS --orgname ORG --hostname HOST
  
Orgname is optional. It will default to "System" if not given.

Information on a random organization that the user has access to will be 
returned.

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

my $login_info = $vcd->login;

my $random_orgid = ( keys %$login_info )[0];

print "\nSelected random ORG of: \"$login_info->{$random_orgid}\" ($random_orgid)\n\n";

my %org = $vcd->get_org( $login_info->{$random_orgid} );

print "\n", Dumper( \%org );
