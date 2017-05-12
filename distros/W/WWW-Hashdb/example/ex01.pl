#!/usr/bin/env perl

use warnings;
use strict;

BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../lib";
}
use WWW::Hashdb;
use XXX;

my $hashdb = WWW::Hashdb->new( limit => 10 );
my @items  = $hashdb->search("BURST CITY");

XXX @items;
