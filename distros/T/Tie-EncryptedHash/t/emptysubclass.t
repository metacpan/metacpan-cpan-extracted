#!/usr/bin/perl -s
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: emptysubclass.t,v 1.1 2000/08/31 16:31:05 vipul Exp vipul $

package Tie::SecretHash;

use lib '../lib';
use lib 'lib';
use Tie::EncryptedHash;
@ISA = qw(Tie::EncryptedHash);


package main;
use Data::Dumper;
no warnings;

%v = ( password => 'Doorknob', 
       password_wrong => 'Bweoo',
       cipher => 'Blowfish',
       plaintext => 'Mirrorshades.',
     );


print "1..45\n";
my $i = 1;
for (qw(Object TiedHash)) {

    if (/Object/) { $h = new Tie::SecretHash }
    if (/Tied/) { $h = {}; tie %$h, Tie::SecretHash }

    $h->{__password} = $v{password};
    $h->{__cipher}   = $v{cipher};


    print qq{($_) STORE/FETCH to/from unencrypted field: \n};
    $h->{plain} = $v{plaintext};
    print $h->{plain} eq $v{plaintext} ? "ok $i\n" : "not ok $i\n"; 
    $i++;

    print qq{($_) STORE/FETCH to/from encrypted field:\n};
    $h->{_encrypted} = $v{plaintext};
    print $h->{_encrypted} eq $v{plaintext} ? "ok $i\n" : "not ok $i\n"; 
    $i++;

    print qq{($_) STORE/FETCH with incorrect password:\n};
    $h->{__password} = $v{password_wrong};
    print $h->{_encrypted} eq $v{plaintext} ? "not ok $i\n" : "ok $i\n";
    $i++;

    print qq{($_) Recover from password change:\n};
    $h->{__password} = $v{password};
    print $h->{_encrypted} eq $v{plaintext} ? "ok $i\n" : "not ok $i\n";
    $i++;

    print qq{($_) EXISTS unencrypted field:\n};
    print exists $h->{plain} ? "ok $i\n" : "not ok $i\n";
    $i++;

    print qq{($_) !EXISTS unencrypted field:\n};
    print exists $$h{plain2} ? "not ok $i\n" : "ok $i\n";
    $i++;

    print qq{($_) EXISTS encrypted field:\n};
    print exists $h->{_encrypted} ? "ok $i\n" : "not ok $i\n";
    $i++;

    print qq{($_) !EXISTS encrypted field:\n};
    print exists $$h{_encrypted2} ? "not ok $i\n" : "ok $i\n";
    $i++;

    print qq{($_) EXISTS encrypted field (incorrect password):\n};
    $h->{__password} = $v{password_wrong};
    print exists $h->{_encrypted} ? "ok $i\n" : "not ok $i\n";
    print Dumper $h;
    $i++;

    print qq{($_) EXISTS encrypted field (incorrect password + hide):\n};
    $h->{__password} = $v{password_wrong};
    $h->{__hide} = "yes";
    print exists $h->{_encrypted} ? "no ok $i\n" : "ok $i\n";
    $i++;
    $h->{__hide} = "no";

    print qq{($_) DELETE plaintext field:\n};
    delete $$h{plain};
    print exists $h->{plain} ? "no ok $i\n" : "ok $i\n";
    $i++;

    print qq{($_) DELETE encrypted field:\n};
    $h->{__password} = $v{password};
    delete $$h{_encrypted};
    print exists $h->{_encrypted} ? "no ok $i\n" : "ok $i\n";
    $i++;

    print qq{($_) FIRSTKEY/NEXTKEY:\n};
    $$h{plain} = $v{plaintext};
    $$h{clone} = $v{plaintext};
    $$h{_encrypted} = $v{plaintext};
    @keys = keys %$h;
    print "@keys\n";
    print $#keys == 2  ? "ok $i\n" : "no ok $i\n";
    $i++;

    print qq{($_) CLEAR Hash with incorrect password:\n};
    $$h{plain} = $v{plaintext};
    $$h{_encrypted} = $v{plaintext};
    $$h{__password} = $v{password_wrong};
    %$h = (); 
    print exists $h->{plain} ? "ok $i\n" : "no ok $i\n";
    $i++;

    print qq{($_) CLEAR Hash with correct password:\n};
    $$h{__password} = $v{password};
    $$h{plain} = $v{plaintext};
    $$h{_encrypted} = $v{plaintext};
    %$h = (); 
    print exists $h->{plain} ? "no ok $i\n" : "ok $i\n";
    $i++;

    undef $h;

}

my %h = ();
tie %h, Tie::SecretHash, 'Blacksun', 'Blowfish';

print "STORE/FETCH explicit reference:\n";
$h{_bamf} = {first => 1.16, second => 0.99 , third => { a => 'b' } };
$h{_age} = 12;
print $h{_bamf}->{third}->{a} eq "b" ? "ok 31\n" : "not ok 31\n";
print $h{_bamf}; 


print "FETCH explicit reference with incorrect password:\n";
$h{__password} = 10;
print "$h{_bamf}\n";
print $h{_bamf} =~ /^Blowfish/ ? "ok 32\n" : "not ok 32\n";

print "Autovivification:\n";
$h{_foo }->{bar}->{cow} = "baw";
print $h{_foo}->{bar}{cow} eq "baw" ? "ok 33\n" : "not ok 33\n";

$h{__password} = "Hownow?";
print "Autovivification with incorrect password:\n";
print $h{_foo}->{bar}{cow} eq "baw" ? "not ok 34\n" : "ok 34\n";

print "Encryption and serialization of implicit references at FETCH:\n";
$h{__password} = 17;
$h{_vivi}->{x} = 4;
$h{__password} = 16;
print $h{_vivi} =~ /^Blowfish/ ? "ok 35\n" : "not ok 35\n";

# checks if autovivification with incorrect password has clobbered our 
# hash.
print "Recovery from password change:\n";
$h{__password} = 10;
$h{_boo}->{bam} = 12;
print $h{_boo}{bam} eq 12 ? "ok 36\n" : "not ok 36\n";

print "More Autovivification:\n";
$h{_bar}{a} = "x";
$h{_bar}{b} = "y";
$h{_bar}{d} = "y";
$h{_bar}{e} = { u => 'y' };
print $h{_bar}{e}{u} eq 'y' ? "ok 37\n" : "not ok 37\n";
$h{__password} = "xx";
print $h{_bar} =~ /^Blowfish/ ? "ok 38\n" : "not ok 38\n";

$h{__password} = "Blacksun";
print "STORE/FETCH encrypted listref:\n";
$h{_list}->[4] = 15;
print $h{_list}->[4] == 15 ? "ok 39\n" : "not ok 39\n";

$h{_linked}{list1}{list2}[6] = 15;
print $h{_linked}{list1}{list2}[6] == 15 ? "ok 40\n" : "not ok 40\n";

print "FETCH encrypted listref with incorrect password:\n";
$h{__password} = 24;
print $h{_linked}{list1}{list2}[6] == 15 ? "not ok 41\n" : "ok 41\n";
print $h{_linked} =~ /^Blowfish/ ? "ok 42\n" : "not ok 42\n";

print "STORE/FETCH encrypted scalarref:\n";
$h{__password} = "Blacksun";
$h{_scalar} = \"string"; 
print ${$h{_scalar}} eq "string" ? "ok 43\n" : "not ok 43\n";

print "STORE/FETCH encrypted scalarref with incorrect password:\n";
$h{__password} = 12;
print ${$h{_scalar}} eq "string" ? "not ok 44\n" : "ok 44\n";
print $h{_scalar} =~ /^Blowfish/ ? "ok 45\n" : "not ok 45";

