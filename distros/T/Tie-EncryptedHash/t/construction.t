#!/usr/bin/perl -s
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: construction.t,v 1.1 2000/08/31 16:31:03 vipul Exp vipul $

use lib '../lib';
use lib 'lib';

use Tie::EncryptedHash;

print "1..2\n";
my %h = ();
tie %h, Tie::EncryptedHash, 'Blacksun', 'Blowfish';

$h{_enc} = "hush hush";
delete $h{__password};
print $h{_enc} =~ /^Blowfish/ ? "ok 1" : "not ok 1";
print qq{\n};

my $h = new Tie::EncryptedHash __password => 'Blacksun', 
                               __cipher => 'DES';

$h->{_enc} = "hush hush";
delete $h->{__password};
print $h->{_enc} =~ /^DES/ ? "ok 2" : "not ok 2";
print qq{\n};


