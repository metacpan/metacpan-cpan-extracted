# -*- perl -*-

# t/001_load.t - check module loading

use Test::Most tests => 8+1;
use Test::NoWarnings;

require "t/global.pl";

use_ok( 'Text::Phonetic' );
use_ok( 'Text::Phonetic::Koeln' );
use_ok( 'Text::Phonetic::DaitchMokotoff' );
use_ok( 'Text::Phonetic::Phonix' );
use_ok( 'Text::Phonetic::Phonem' );

load_conditional('Text::Phonetic::Metaphone','Text::Metaphone');
load_conditional('Text::Phonetic::DoubleMetaphone','Text::DoubleMetaphone');
load_conditional('Text::Phonetic::Soundex','Text::Soundex');
#load_conditional('Text::Phonetic::MultiPhone','Text::MultiPhone');

