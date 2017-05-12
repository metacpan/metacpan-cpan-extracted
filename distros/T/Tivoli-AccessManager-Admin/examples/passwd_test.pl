#!/usr/bin/perl
use strict;
use warnings;
use Term::ReadKey

use TAMeb::Admin;

my ( $resp, $rc, @groups, $pswd );

ReadMode 2;
print "sec_master password: ";
$pswd = <STDIN>;
ReadMode 0;
chomp $pswd;

my $pd  = TAMeb::Admin::Context->new(password => $pswd );

for ( 1 .. 20 ) {
    my $name = sprintf "user%02d", $_;
    my $user = TAMeb::Admin::User->new( $pd, name => $name );

    $resp = $user->passwordvalid( valid => 0 );
    unless ( $resp->isok() ) {
	warn "Couldn't set user $name password valid: ", $resp->messages(), "\n";
    }
}

END {
    ReadMode 0;
}
