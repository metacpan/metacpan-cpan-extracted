#!/usr/bin/perl
use strict;
use FindBin qw($Bin $Script);
use File::Spec;
use Test::More;
BEGIN {
    eval {
       require File::ReadBackwards;
       File::ReadBackwards->import;
       require Package::Alias;
    };
    if ($@){
        Test::More::plan( skip_all => "Package::Alias and File::ReadBackwards required for testing FRB aliased reading files backwards" );
    }
}
Test::More::plan( tests =>1 );
use ToolSet::y;

my $f = FRB->new(File::Spec->catfile($Bin, $Script)); 
ok ($f->readline() =~ /^ok/, "y can FRB read backwards");
