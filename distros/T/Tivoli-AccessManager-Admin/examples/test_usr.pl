#!/usr/bin/perl 
use strict;
use warnings;
use Term::ReadKey;

use TAMeb::Admin;
use Devel::Peek;

my ( $resp, $rc, @groups, $pswd );

ReadMode 2;
print "sec_master password: ";
$pswd = <STDIN>;
ReadMode 0;
chomp $pswd;

my $pd  = TAMeb::Admin::Context->new(password => $pswd );
my $user = TAMeb::Admin::User->new( $pd, name => 'norton' );

if ( $user->exist() ) {
    print $user->{name}, " already exists\n";
    print STDERR Dump( $user ), "\n";
}
else {
    print $user->{name}, " doesn't exist -- creating\n";
    $resp = $user->create( $pd, dn => "cn=norton,ou=people,o=rox,c=us",
				cn => 'ed',
				sn => 'norton',
				password => 'welcome1',
			  );
    if ( $resp->isok() ) {
	print "Norton was created\n";
    }
    else {
	print "Error creating Norton:\n";
	print $resp->messages(), "\n";
	exit 1;
    }
}


END {
    ReadMode 0;
}
