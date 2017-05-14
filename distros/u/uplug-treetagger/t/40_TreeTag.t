#!/usr/bin/perl
#-*-perl-*-

use FindBin qw( $Bin );
use lib $Bin. '/../lib';

use Test::More;
use File::Compare;

use Uplug;

my $UPLUG = 'uplug';
my $DATA  = $Bin.'/data';

my $null = "2> /dev/null >/dev/null";


for $l ('de','en','fr'){
    system("$UPLUG pre/$l/toktag -in $DATA/xml/1988$l.sent.xml -out pos_$l.xml $null");
    is( compare( "pos_$l.xml", "$DATA/xml/1988$l.tree.xml" ),0, "$l POS tagged (TreeTagger)" );
    unlink("pos_$l.xml");
}

done_testing;

