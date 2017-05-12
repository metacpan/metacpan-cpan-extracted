#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
use Test::More::UTF8;
use Text::TEI::Collate::Lang::Greek;

my $comp = \&Text::TEI::Collate::Lang::Greek::comparator;
is( $comp->( "αι̣τια̣ν̣" ), "αιτιαν", "Got correct comparison string for Greek underdots" );
}




1;
