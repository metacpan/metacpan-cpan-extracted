#!/usr/bin/perl

my $host = '127.0.0.1';
my $port = '389';
my $user = '';
my $pass = '';
my $base = 'ou=Test, o=IMASY, c=JP';
my $full = 'cn=tai, ou=Test, o=IMASY, c=JP';

use Test;

BEGIN { plan test => 7 };

use Tie::LDAP;

unless ($ENV{RUN_TEST}) {
  foreach (1..7) { ok(1); } exit(0);
}

## connect - edit parameters as needed
tie %LDAP, 'Tie::LDAP', {
    host => $host,
    port => $port,
    user => $user,
    pass => $pass,
    base => $base,
};
ok(tied(%LDAP));

## insert entry
$LDAP{$full} = {
    name => ['tai'],
    mail => ['tai@imasy.or.jp'],
    link => ['http://www.imasy.or.jp/'],
    host => ['www.imasy.or.jp', 'mail.imasy.or.jp'],
};
ok($LDAP{$full});

## disconnect
untie(%LDAP); %LDAP = ();

## connect - edit parameters as needed
tie %LDAP, 'Tie::LDAP', {
    host => $host,
    port => $port,
    user => $user,
    pass => $pass,
    base => $base,
};
ok(tied(%LDAP));

## fetch-and-compare
ok($LDAP{$full}->{name}->[0] eq 'tai');
ok($LDAP{$full}->{mail}->[0] eq 'tai@imasy.or.jp');
ok($LDAP{$full}->{link}->[0] eq 'http://www.imasy.or.jp/');
ok($LDAP{$full}->{host}->[0] eq 'www.imasy.or.jp' ||
   $LDAP{$full}->{host}->[0] eq 'mail.imasy.or.jp');

## scan-trough
1 while (my($dn, $hash) = each %LDAP);

## disconnect
untie(%LDAP); %LDAP = ();

exit(0);
