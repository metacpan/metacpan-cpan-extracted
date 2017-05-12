#!/usr/bin/perl
use strict;
use warnings;
use Term::ReadKey;
use TAMeb::Admin;
use Data::Dumper;

my ($resp,$pswd);

ReadMode 2;
print "sec_master password: ";
$pswd = <STDIN>;
ReadMode 0;
chomp $pswd;

my $pd  = TAMeb::Admin::Context->new(password => $pswd );
my $pop = TAMeb::Admin::POP->new( $pd, name => 'harry' );

if ( $pop->exist ) {
    print "Hmm.  harry already exists.  Fixing that\n";
    $resp = $pop->delete;
    unless ( $resp->isok ) {
	print "ERROR deleting harry:\n";
	die $resp->messages;
    }
    print "harry deleted\n";
}

print "harry doesn't exist.  Creating\n";
$resp = $pop->create;
unless ( $resp->isok ) {
    print "ERROR creating harry:\n";
    die $resp->messages;
}
print "harry created\n";

print "Setting TOD Access on harry\n";
$resp = $pop->tod( days => [ qw/ mon tue fri/ ],
		   start => '0900',
		   end   => '1730',
		   reference => 'local'
		  );
if ( $resp->isok ) {
    print Dumper( $resp->value );
}
else {
    print "ERROR setting TOD:\n";
    die $resp->messages
}

print "Setting audit level\n";
$resp = $pop->auditlevel( 
    		   level => [ qw/ permit error/ ],
		  );
if ( $resp->isok ) {
    print Dumper( $resp->value );
}
else {
    die $resp->messages
}

print "Setting IP auth\n";
$resp = $pop->ipauth( add => { '192.168.8.1' => { NETMASK => '255.255.254.0',
					      LEVEL   => 1
					  },
			       '10.1.1.1' => { NETMASK => '255.0.0.0',
			       		     LEVEL => 2 }
			     } );
if ( $resp->isok ) {
    print Dumper( $resp->value );
}
else {
    print "ERROR setting ipauth:\n";
    die $resp->messages;
}

END {
    ReadMode 0;
}
