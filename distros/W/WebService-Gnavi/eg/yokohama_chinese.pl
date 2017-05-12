#!/usr/bin/perl
use strict;
use WebService::Gnavi;
use YAML;

my $gnavi = WebService::Gnavi->new(access_key => shift @ARGV);
my $res   = $gnavi->search({
    category_l => 'CTG300',
    address    => '横浜'
});

print Dump [ $res->list ]