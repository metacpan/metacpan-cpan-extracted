#!/usr/bin/perl -s
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: reforgy.t,v 1.1 2000/08/31 16:31:16 vipul Exp vipul $

use lib '../lib';
use lib 'lib';
no warnings;

use Tie::EncryptedHash;
use Data::Dumper qw(DumperX);

my @a = ('Araa'..'Zeck');
sub ralpha { _.$a[int(rand(26))] }
sub rnum { return int(rand(4)) }

print "1..1\n";
print "generating a large, random data structure...\n";

my %h = (); tie %h, Tie::EncryptedHash, 'Blacksun', 'Blowfish';

for ( 1..50 ) {
    my $rnd =  int(rand(7));
    if ( $rnd == 1 ) { 
        $h{ralpha()}->[rnum()] = { ralpha() => ralpha().ralpha() };
    } elsif ( $rnd == 2 ) { 
        $h{ralpha()}->[rnum()]->{ralpha()} => ralpha ();
    } elsif ( $rnd == 3 ) { 
        $h{ralpha()}->[rnum()] = { ralpha() => [1..rnum()] }
    } elsif ( $rnd == 4 ) { 
        $h{ralpha()}->[rnum()]->{'HASH_' . ralpha()} = { ralpha() => ralpha() };
    } elsif ( $rnd == 5 ) { 
        $h{ralpha()}->[rnum()]->{'ARRAY_' . ralpha()} = ralpha ();
    } elsif ( $rnd == 6 ) { 
        for ( 0 .. rnum() ) {
         $h{ralpha()}->[rnum()]->{ralpha()}->[$_] = { ralpha() => [1..rnum()] };
         $h{ralpha()}->[$_] = { ralpha() => [1..rnum()] };
        }
    }
}

$h{__password} = "sds"; print DumperX \%h;
$h{__password} = "Blacksun"; print DumperX \%h;

print "ok 1\n";
