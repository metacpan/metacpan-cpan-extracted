# -*- perl -*-

# t/002_load.t - some general checks

use Test::Most tests => 8+1;
use Test::NoWarnings;

use_ok( 'Text::Phonetic' );

my @list = Text::Phonetic->available_algorithms();

explain('Found '.scalar @list);
ok(scalar @list >= 7,'Found at least 7 installed algorithms');
ok((grep { $_ eq 'Soundex'} @list),'Found soundex algorithm');

ok(Text::Phonetic::_is_inlist('hase','baer','hase','luchs'),'Helper function ok');
ok(! Text::Phonetic::_is_inlist('hase','baer','ratte','luchs'),'Helper function ok');
ok(Text::Phonetic::_is_inlist('hase',['baer','hase','luchs']),'Helper function ok');

ok(Text::Phonetic::_compare_list(['hase','baer'],['luchs','ratte','hase']),'Helper function ok');
ok(! Text::Phonetic::_compare_list(['hase','baer'],['luchs','ratte']),'Helper function ok');