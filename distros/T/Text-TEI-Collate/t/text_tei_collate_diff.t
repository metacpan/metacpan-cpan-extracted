#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
use lib 'lib';
use Test::More::UTF8;
use Text::TEI::Collate;
my @mss;
my $aligner = Text::TEI::Collate->new();
push( @mss, $aligner->read_source( 'Արդ ահա մինչև ցայս վայրս բազմաջան զհարիւրից ամացն զորս բազում' ) );
push( @mss, $aligner->read_source( 'Արդ մինչև ցայս վայրս բազմեջան զ100ից ամաց զօրս ի բազում' ) );
$aligner->make_fuzzy_matches( $mss[0]->words, $mss[1]->words );
my $diff = Text::TEI::Collate::Diff->new( $mss[0]->words, $mss[1]->words, $aligner );
# First chunk should be Same, length 1
my $pos = $diff->Next();
ok( $pos );
ok( $diff->Same, "first chunk same" );
is( scalar $diff->Items(1), 1, "first chunk has 1 item ");
# Second chunk should be Del, length 1
$pos = $diff->Next();
ok( $pos );
is( scalar $diff->Items(1), 1, "second chunk has 1 base" );
is( scalar $diff->Items(2), 0, "second chunk has 0 new" );
# Third chunk should be Same, length 4
$pos = $diff->Next();
ok( $pos );
ok( $diff->Same, "third chunk same" );
is( scalar $diff->Items(1), 4, "third chunk has 4 items" );
# Fourth chunk should be Different, length 1
$pos = $diff->Next();
ok( $pos );
ok( !$diff->Same, "fourth chunk different" );
is( scalar $diff->Items(1), 1, "fourth chunk has 1 base " );
is( scalar $diff->Items(2), 1, "fourth chunk has 1 new" );
# Fifth chunk should be Same, length 2
$pos = $diff->Next();
ok( $pos );
ok( $diff->Same, "fifth chunk same" );
is( scalar $diff->Items(1), 2, "fifth chunk has 2 items ");
# Sixth chunk should be Add, length 1
$pos = $diff->Next();
ok( $pos );
is( scalar $diff->Items(1), 0, "sixth chunk has 0 base" );
is( scalar $diff->Items(2), 1, "sixth chunk has 1 new" );
# Seventh chunk should be Same, length 1
$pos = $diff->Next();
ok( $pos );
ok( $diff->Same, "seventh chunk same" );
is( scalar $diff->Items(1), 1, "seventh chunk has 1 item" );
# No more chunks
$pos = $diff->Next;
ok( !$pos );
}




1;
