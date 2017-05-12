#!/usr/bin/perl
use strict;
use warnings;
use Term::ReadKey;

use TAMeb::Admin;
use TAMeb::Admin::Server::Webseal;
use Data::Dumper;

my ( $resp, $serv, $jct, $pswd );

#ReadMode 2;
#print "sec_master password: ";
#$pswd = <STDIN>;
#ReadMode 0;
#print "\n";
#chomp $pswd;
$pswd = '4nd3rson';

my $pd  = TAMeb::Admin::Context->new(password => $pswd );
my $seal = TAMeb::Admin::Server::Webseal->new( $pd, hostname => 'mojo');

$|++;

$resp = $seal->show( junction => '/monkey' );
unless ( $resp->isok ) {
    die $resp->messages;
}
$jct = $resp->value;
$serv = TAMeb::Admin::Junction::Backend->new(  hostname => 'mojo',
					     port     => 2002
					   );
$resp = $serv->add( webseal => $seal );
die $resp->messages unless $resp->isok;

print "Added the server -- press <ENTER> to continue";
my $enter = <STDIN>;

$resp = $serv->remove( webseal => $seal );
die $resp->messages unless $resp->isok;

print "Deleted the server\n"; 

#END {
#    ReadMode 0;
#}
