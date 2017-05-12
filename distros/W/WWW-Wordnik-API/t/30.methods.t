#!/usr/bin/env perl

use strict;
use warnings;
use constant TESTS   => 20;
use Test::More tests => TESTS;

BEGIN { use_ok('WWW::Wordnik::API'); }
require_ok('WWW::Wordnik::API');

my $wn = WWW::Wordnik::API->new();
$wn->debug(1);

my @responses = <DATA>;
chomp @responses;

is( $wn->word('Perl'), shift @responses, 'word with no options' );
is( $wn->word( 'Perl', useSuggest => 'true' ),
    shift @responses,
    'word with useSuggest'
);
is( $wn->word( 'Perl', literal => 'false' ),
    shift @responses,
    'word with literal'
);
is( $wn->phrases('Python'), shift @responses, 'phrases with no options' );
is( $wn->phrases( 'Python', count => 10 ),
    shift @responses,
    'phrases with count'
);
is( $wn->definitions('Ruby'),
    shift @responses,
    'definitions with no options'
);
is( $wn->definitions( 'Ruby', count => 20 ),
    shift @responses,
    'definitions with count'
);
is( $wn->definitions(
        'Ruby',
        partOfSpeech => [
            qw/noun verb adjective adverb idiom article abbreviation preposition prefix interjection suffix/
        ]
    ),
    shift @responses,
    'definitions with partOfSpeech'
);
is( $wn->examples('Java'), shift @responses, 'examples' );
is( $wn->related('Lisp'),  shift @responses, 'related with no options' );
is( $wn->related(
        'Lisp', type => [qw/synonym antonym form hyponym variant verb-stem verb-form cross-reference same-context/]
    ),
    shift @responses,
    'related with type'
);
is( $wn->frequency('Scheme'),         shift @responses, 'frequency' );
is( $wn->punctuationFactor('Prolog'), shift @responses, 'punctuationFactor' );
is( $wn->suggest('C'), shift @responses, 'suggest with no options' );
is( $wn->suggest( 'C', count => 4 ), shift @responses, 'suggest with count' );
is( $wn->suggest( 'C', startAt => 6 ),
    shift @responses,
    'suggest with startAt'
);
is( $wn->wordoftheday, shift @responses, 'wordoftheday' );
is( $wn->randomWord( hasDictionaryDef => 'true' ),
    shift @responses, 'randomWord' );

done_testing(TESTS);

__DATA__
http://api.wordnik.com/v4/word.json/Perl
http://api.wordnik.com/v4/word.json/Perl?useSuggest=true
http://api.wordnik.com/v4/word.json/Perl?literal=false
http://api.wordnik.com/v4/word.json/Python/phrases
http://api.wordnik.com/v4/word.json/Python/phrases?count=10
http://api.wordnik.com/v4/word.json/Ruby/definitions
http://api.wordnik.com/v4/word.json/Ruby/definitions?count=20
http://api.wordnik.com/v4/word.json/Ruby/definitions?partOfSpeech=noun,verb,adjective,adverb,idiom,article,abbreviation,preposition,prefix,interjection,suffix
http://api.wordnik.com/v4/word.json/Java/examples
http://api.wordnik.com/v4/word.json/Lisp/related
http://api.wordnik.com/v4/word.json/Lisp/related?type=synonym,antonym,form,hyponym,variant,verb-stem,verb-form,cross-reference,same-context
http://api.wordnik.com/v4/word.json/Scheme/frequency
http://api.wordnik.com/v4/word.json/Prolog/punctuationFactor
http://api.wordnik.com/v4/suggest.json/C
http://api.wordnik.com/v4/suggest.json/C?count=4
http://api.wordnik.com/v4/suggest.json/C?startAt=6
http://api.wordnik.com/v4/wordoftheday.json
http://api.wordnik.com/v4/words.json/randomWord?hasDictionaryDef=true
