#!perl

use Test::More tests => 7;
use Test::OpenLDAP();

SKIP: {
	if (my $skipReason = Test::OpenLDAP->skip()) {
		skip($skipReason, 3);
	} else {
		my $slapd = Test::OpenLDAP->new();
		my $ldap = Net::LDAP->new($slapd->uri());
		ok($ldap, "Successfully connected to slapd at " . $slapd->uri() . ":$@");
		my $mesg = $ldap->bind($slapd->admin_user(), 'password' => $slapd->admin_password());
		ok($mesg->code() == 0, "Successful bind as '" . $slapd->admin_user() . ":" . $mesg->error());
		$slapd->stop();
		$slapd->start();
		$ldap = Net::LDAP->new($slapd->uri());
		ok($ldap, "Successfully re-connected to slapd at " . $slapd->uri() . " after slapd was restarted:$@");
	}
	if (my $skipReason = Test::OpenLDAP->skip()) {
		skip($skipReason, 4);
	} else {
		my $slapd = Test::OpenLDAP->new({ 'suffix' => 'dc=foobar,dc=example,dc=org' });
		my $ldap = Net::LDAP->new($slapd->uri());
		ok($slapd->suffix() eq 'dc=foobar,dc=example,dc=org', "->suffix() returned correctly");
		ok($slapd->admin_user() eq 'cn=root,dc=foobar,dc=example,dc=org', "->admin_user was correctly changed");
		ok($ldap, "Successfully connected to slapd at " . $slapd->uri() . ":$@");
		my $mesg = $ldap->bind($slapd->admin_user(), 'password' => $slapd->admin_password());
		ok($mesg->code() == 0, "Successful bind as '" . $slapd->admin_user() . ":" . $mesg->error());
		$slapd->DESTROY();
	}
}
		
