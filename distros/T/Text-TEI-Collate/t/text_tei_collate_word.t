#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
use Test::More::UTF8;
use Text::TEI::Collate::Word;
use Encode qw( encode_utf8 );

# Initialize a word from a string, check its values

my $word = Text::TEI::Collate::Word->new( string => 'ἔστιν;', ms_sigil => 'A' );
is( $word->word, "ἔστιν", "Got correct word from string");
is( $word->comparison_form, "εστιν", "Got correct normalization from string");
is_deeply( [ $word->punctuation], [ { 'char' => ';', 'pos' => 5 } ], "Got correct punctuation from string");
is( $word->canonical_form, $word->word, "Canonical form is same as passed form");
ok( !$word->invisible, "Word is not invisible");
ok( !$word->is_empty, "Word is not empty");

# Initialize a word from a JSON string, check its values
use JSON qw( decode_json );
my $jstring = encode_utf8( '{"c":"Արդ","n":"արդ","punctuation":[{"char":"։","pos":3}],"t":"Առդ"}' );
$word = Text::TEI::Collate::Word->new( json => decode_json($jstring), ms_sigil => 'B' );
is( $word->word, 'Առդ', "Got correct JSON word before modification" );
is( $word->canonical_form, 'Արդ', "Got correct canonized form" );
is( $word->comparison_form, 'արդ', "Got correct normalized form" );
is( $word->original_form, 'Առդ։', "Restored punctuation correctly for original form");

# Initialize an empty word, check its values
$word = Text::TEI::Collate::Word->new( empty => 1 );
is( $word->word, '', "Got empty word");
ok( $word->is_empty, "Word is marked empty" );

# Initialize a special, check its values and its 'printable'

# Initialize a word with a canonizer, check its values
$word = Text::TEI::Collate::Word->new( string => 'Ἔστιν;', ms_sigil => 'D', canonizer => sub{ lc( $_[0])});
is( $word->word, 'Ἔστιν', "Got correct word before canonization" );
is( $word->canonical_form, 'ἔστιν', "Got correct canonized word");
}




1;
