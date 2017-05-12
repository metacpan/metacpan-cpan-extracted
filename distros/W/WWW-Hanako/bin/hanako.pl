#!/usr/bin/perl -w

use 5.010000;
use strict;
use warnings;
use lib './lib';
use WWW::Hanako;
use Carp;
use Getopt::Std;
use Data::Dumper;

my %opt;
getopts('td', \%opt);

my $area = shift || 3;
my $mst = shift || 51300200;
my $today=$opt{t} || 0;
my $debug=$opt{d} || 0;

my $hanako = WWW::Hanako->new(area=>$area, mst=>$mst, debug=>$debug);

if($today){
    my @list = $hanako->today();
    for(@list){
        printf("%2d %4d %2d %2d %2d %2d\n",
        $_->{hour},
        $_->{pollen},
        $_->{wd},
        $_->{ws},
        $_->{temp},
        $_->{prec});
    }
}else{
    my $now = $hanako->now();
    printf("%2d %4d %2d %2d %2d %2d\n",
           $now->{hour},
           $now->{pollen},
           $now->{wd},
           $now->{ws},
           $now->{temp},
           $now->{prec});
}
