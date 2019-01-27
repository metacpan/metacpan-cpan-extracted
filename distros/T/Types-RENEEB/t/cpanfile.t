#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Test::More;
use File::Basename;
use Module::CPANfile;
use lib dirname(__FILE__);
use CpanfileTest;

use Types::RENEEB qw(CPANfile);

my $sub = CPANfile();
my $cpanfile = dirname(__FILE__) . '/../cpanfile';

my @good = (Module::CPANfile->load( $cpanfile ) ); 
my @bad  = (__FILE__);

for my $good ( @good ) {
    ok $sub->($good);
}

for my $bad ( @bad ) {
    my $error;
    eval { $sub->($bad); 1; } or $error = $@;

    my $re = defined $bad ? qr/Value ".*?" did not pass/ : qr/Undef did not pass/;
    like $error, $re, sprintf "Bad value: '%s'", $bad // '<undef>';
}

{
    my $obj = CpanfileTest->new( cf => $cpanfile );
    isa_ok $obj, 'CpanfileTest';
    isa_ok $obj->cf, 'Module::CPANfile';
}

{
    my $obj = CpanfileTest->new( cf => $good[0] );
    isa_ok $obj, 'CpanfileTest';
    isa_ok $obj->cf, 'Module::CPANfile';
}

done_testing();

