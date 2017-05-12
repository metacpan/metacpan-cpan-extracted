#!/usr/bin/perl -s
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: hide.t,v 1.1 2000/08/31 16:31:07 vipul Exp vipul $

use lib '../lib';
use lib 'lib';

use Tie::EncryptedHash; 
no warnings;
print "1..4\n";
my %h = ();
tie %h, Tie::EncryptedHash, 'Blacksun';

my $i = 1;
$h{_a} = 'b';
$h{_b}{c}{d} = "meme";
$h{__hide} = 1;
delete $h{__password};
print $h{_a} eq "" ? "ok $i\n" : "not ok $i\n";
$i++;

print $h{_b} eq "" ? "ok $i\n" : "not ok $i\n";
$i++;

delete $h{__hide };
print $h{_a} =~ /^Blowfish/ ? "ok $i\n" : "not ok $i\n";
$i++;

print $h{_b} =~ /^Blowfish/ ? "ok $i\n" : "not ok $i\n";
$i++;


