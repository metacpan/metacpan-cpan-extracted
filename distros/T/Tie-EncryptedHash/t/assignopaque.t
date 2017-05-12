#!/usr/bin/perl -s
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: assignopaque.t,v 1.1 2000/08/31 16:31:00 vipul Exp vipul $

use lib '../lib';
use lib 'lib';
use Tie::EncryptedHash;

print "1..1\n";
my %h = ();
tie %h, Tie::EncryptedHash, 'Blacksun', 'Blowfish';

$h{_enc} = "hush hush";
delete $h{__password};
$u = $h{_enc};

my %g = ();
tie %g, Tie::EncryptedHash; 
$g{_secret} = $u;
$g{__password} = 'Blacksun';
print $g{_secret} =~ /hush hush/ ? "ok 1\n" : "not ok 1\n";
