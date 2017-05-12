#!/usr/bin/perl
use strict;
use warnings;
use Term::ReadKey;
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

    if ( $user->exist() ) {
	print $user->{name}, " already exists\n";
	print STDERR Dump( $user ), "\n";
    }
    else {
	print $user->{name}, " doesn't exist -- creating\n";
	$resp = $user->create( dn => "cn=$name,ou=people,o=encodeinc,c=us",
			       cn => 'Test',
			       sn => $name,
			       password => "welcome$_",
			      );
	if ( $resp->isok() ) {
	    print "$name was created\n";
	}
	else {
	    print "Error creating $name:\n";
	    print $resp->messages(), "\n";
	    exit 1;
	}
    }
}

END {
    ReadMode 0;
}
