#!/usr/bin/perl
use strict;
use warnings;
use TAMeb::Admin;
use Data::Dumper;

my ( $resp, $serv, $pswd );

ReadMode 2;
print "sec_master password: ";
$pswd = <STDIN>;
ReadMode 0;
chomp $pswd;

my $pd  = TAMeb::Admin::Context->new(password => $pswd );
my $rsvp = TAMeb::Admin::Response->new;
my $seal = 'default-webseald-localhost';
my $wpm  = 'amwpm-mojo';

$serv = TAMeb::Admin::Server->new( $pd );

$resp = $serv->server_gettasklist( $rsvp, $seal );
print Dumper( $resp );

$resp = $serv->server_performtask( $rsvp, $seal, 'list' );
print Dumper( $resp );

$resp = $serv->server_performtask( $rsvp, $seal, 'show /monkey2' );
print Dumper( $resp );

$resp = $serv->server_gettasklist( $rsvp, $wpm );
print Dumper( $resp );


END {
    ReadMode 0;
}
