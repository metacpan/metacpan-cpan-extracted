#!/usr/bin/perl -w
use strict;
use Time::Skew;
use Data::Dumper;

my $hull=[];
my $result={};
my ( $time, $delay );
my $k=0;
open DATA,"test.data";
while ( <DATA> ) {
    ( $time, $delay ) = split /\s+/,$_;
    Time::Skew::convexhull($result,[$time,$delay],$hull);
    ( defined $result->{skewjitter} ) || next;

}

print Dumper($hull);
print Dumper($result);
 
