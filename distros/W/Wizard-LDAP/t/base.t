# -*- perl -*-

use strict;

$| = 1;
$^W = 1;


my @modules = qw(Wizard::LDAP
	         Wizard::LDAP::Host
	         Wizard::LDAP::Net
	         Wizard::LDAP::User
		 Wizard::SaveAble::LDAP);


print "1..", scalar(@modules), "\n";

my $i = 0;
foreach my $m (@modules) {
    ++$i;
    eval "require $m";
    if ($@) {
	print STDERR "Error while loading $m:\n$@\n";
	print "not ok $i\n";
    } else {
	print "ok $i\n";
    }
}
