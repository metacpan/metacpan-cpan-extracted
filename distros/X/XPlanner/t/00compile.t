#!/usr/bin/perl -w

use Test::More 'no_plan';
use File::Find;

find({ no_chdir => 1,
       wanted   => sub {
           return unless /\.pm$/;
    
           (my $mod = $File::Find::name) =~ s{/}{::}g;
           $mod =~ s/\.pm$//;
           $mod =~ s/lib:://;

           use_ok $mod;
       }
     }, 
     "lib"
);
