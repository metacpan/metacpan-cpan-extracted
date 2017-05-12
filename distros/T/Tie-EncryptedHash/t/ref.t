#!/usr/bin/perl -s
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: ref.t,v 1.1 2000/08/31 16:31:13 vipul Exp vipul $

use lib '../lib';
use lib 'lib';
use Tie::EncryptedHash;
use Data::Dumper;
no warnings;

print "1..15\n";
my %h = ();
tie %h, Tie::EncryptedHash, 'Blacksun', 'Blowfish';

print "STORE/FETCH explicit reference:\n";
$h{_bamf} = {first => 1.16, second => 0.99 , third => { a => 'b' } };
$h{_age} = 12;
print $h{_bamf}->{third}->{a} eq "b" ? "ok 1\n" : "not ok 1\n";
print $h{_bamf}; 

print "FETCH explicit reference with incorrect password:\n";
$h{__password} = 10;
#delete $h{__password};
print "$h{_bamf}\n";
print $h{_bamf} =~ /^Blowfish/ ? "ok 2\n" : "not ok 2\n";

print "Autovivification:\n";
$h{__password} = "foobar";
$h{_foo }->{bar}->{cow} = "baw";
print $h{_foo}->{bar}{cow} eq "baw" ? "ok 3\n" : "not ok 3\n";

$h{__password} = "Hownow?";
print "Autovivification with incorrect password:\n";
print $h{_foo}->{bar}{cow} eq "baw" ? "not ok 4\n" : "ok 4\n";

print "Encryption and serialization of implicit references at FETCH:\n";
$h{__password} = 17;
$h{_vivi}->{x} = 4;
$h{__password} = 16;
print $h{_vivi} =~ /^Blowfish/ ? "ok 5\n" : "not ok 5\n";

# checks if autovivification with incorrect password has clobbered our 
# hash.
print "Recovery from password change:\n";
$h{__password} = 10;
$h{_boo}->{bam} = 12;
print $h{_boo}{bam} eq 12 ? "ok 6\n" : "not ok 6\n";

print "More Autovivification:\n";
$h{_bar}{a} = "x";
$h{_bar}{b} = "y";
$h{_bar}{d} = "y";
$h{_bar}{e} = { u => 'y' };
print $h{_bar}{e}{u} eq 'y' ? "ok 7\n" : "not ok 7\n";
$h{__password} = "xx";
print $h{_bar} =~ /^Blowfish/ ? "ok 8\n" : "not ok 8\n";

$h{__password} = "Blacksun";
print "STORE/FETCH encrypted listref:\n";
$h{_list}->[4] = 15;
print $h{_list}->[4] == 15 ? "ok 9\n" : "not ok 9\n";

$h{_linked}{list1}{list2}[6] = 15;
print $h{_linked}{list1}{list2}[6] == 15 ? "ok 10\n" : "not ok 10\n";

print "FETCH encrypted listref with incorrect password:\n";
$h{__password} = 24;
print $h{_linked}{list1}{list2}[6] == 15 ? "not ok 11\n" : "ok 11\n";
print $h{_linked} =~ /^Blowfish/ ? "ok 12\n" : "not ok 12\n";

print "STORE/FETCH encrypted scalarref:\n";
$h{__password} = "Blacksun";
$h{_scalar} = \"string"; 
print ${$h{_scalar}} eq "string" ? "ok 13\n" : "not ok 13\n";

print "STORE/FETCH encrypted scalarref with incorrect password:\n";
$h{__password} = 12;
print ${$h{_scalar}} eq "string" ? "not ok 14\n" : "ok 14\n";
print $h{_scalar} =~ /^Blowfish/ ? "ok 15\n" : "not ok 15";

