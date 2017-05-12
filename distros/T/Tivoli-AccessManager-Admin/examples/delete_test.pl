#!/usr/bin/perl
use strict;
use warnings;

use TAMeb::Admin;
use Term::ReadKey;

my ( $resp, $rc, @groups, $pswd );

ReadMode 2;
print "sec_master password: ";
$pswd = <STDIN>;
ReadMode 0;
chomp $pswd;

my $pd  = TAMeb::Admin::Context->new(password => $pswd );

for ( 21 .. 200 ) {
    my $name = sprintf "user%03d", $_;
    my $user = TAMeb::Admin::User->new( $pd, name => $name );

    if ( $user->exist() ) {
	print $user->{name}, " exists -- deleting\n";
	$resp = $user->delete(registry=>1);
	if ( $resp->isok() ) {
	    print "$name was deleted\n";
	}
	else {
	    print "Error deleting $name:\n";
	    print $resp->messages(), "\n";
	    exit 1;
	}
    }
}

END {
    ReadMode 0;
}
