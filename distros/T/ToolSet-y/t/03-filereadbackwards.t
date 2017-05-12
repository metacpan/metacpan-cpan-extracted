#!/usr/bin/perl
use strict;
use FindBin qw($Bin $Script);
use File::Spec;
use Test::More;
BEGIN {
    eval {
       require File::ReadBackwards;
       File::ReadBackwards->import;
    };
    if ($@){
        Test::More::plan( skip_all => "File::ReadBackwards required for testing reading files backwards" );
    }
}
Test::More::plan( tests =>1 );
use ToolSet::y;

my $f = File::ReadBackwards->new(File::Spec->catfile($Bin, $Script)); 
ok ($f->readline() =~ /^ok/, "y can read backwards");
