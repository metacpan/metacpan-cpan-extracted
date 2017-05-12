#!/usr/bin/perl -s
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: opertations.t,v 1.1 2000/08/31 16:31:10 vipul Exp vipul $

use lib 'lib';
use lib '../lib';
use lib '/home/vipul/PERL/crypto/secrethash/lib';

use Tie::EncryptedHash; 
use Crypt::Blowfish;
use Data::Dumper;

%v = ( password => 'Doorknob', 
       password_wrong => 'Bweoo',
       cipher => 'Blowfish',
       plaintext => 'Mirrorshades.',
     );


print "1..30\n";
my $i = 1;
for (qw(Object TiedHash)) {

    if (/Object/) { $h = new Tie::EncryptedHash }
    if (/Tied/) { $h = {}; tie %$h, Tie::EncryptedHash }

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


