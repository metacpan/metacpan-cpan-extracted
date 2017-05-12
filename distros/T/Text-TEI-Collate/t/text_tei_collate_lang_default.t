#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
use Test::More::UTF8;
use Text::TEI::Collate::Lang::Default;

my $distsub = \&Text::TEI::Collate::Lang::Default::distance;
is( $distsub->( 'bedwange', 'bedvanghe' ), 3, "Correct alpha distance bedwange" );
is( $distsub->( 'swaer', 'suaer' ), 2, "Correct alpha distance swaer" );
is( $distsub->( 'the', 'teh' ), 0, "Correct alpha distance the" );
is( $distsub->( 'αι̣τια̣ν̣', 'αιτιαν' ), 3, "correct distance one direction" );
is( $distsub->( 'αιτιαν', 'αι̣τια̣ν̣' ), 3, "correct distance other direction" );
}



# =begin testing
{
use Test::More::UTF8;
use Text::TEI::Collate::Lang::Default;

my $comp = \&Text::TEI::Collate::Lang::Default::comparator;
is( $comp->( 'abcd' ), 'abcd', "Got correct no-op comparison string" );
is( $comp->( "ἔστιν" ), "εστιν", "Got correct unaccented comparison string");
}




1;
