use strict;

package main;

use Test;

use Text::Query;

plan test => 18;

#
# ParseSimple logic
#
{
    my($question);
    my($query) = Text::Query->new(-build=>'Text::Query::Build',-solve=>'Text::Query::Solve');

    $question = "10";
    $query->prepare($question);
    ok($query->matchstring(), "[ literal 10 ]", "prepare $question");

    $question = "+10 +20";
    $query->prepare($question);
    ok($query->matchstring(), "[ or [ mandatory [ literal 10 ] ] [ mandatory [ literal 20 ] ] ]", "prepare $question");

    $question = "+10 20 -30";
    $query->prepare($question);
    ok($query->matchstring(), "[ or [ or [ mandatory [ literal 10 ] ] [ literal 20 ] ] [ forbiden [ literal 30 ] ] ]", "prepare $question");

}

#
# ParseAdvanced logic
#
{
    my($question);
    my($query) = Text::Query->new('bluf', -verbose => 0);
    $query->configure(-parse => 'Text::Query::ParseAdvanced',-build=>'Text::Query::Build');

    $question = "word1";
    $query->prepare($question);
    ok($query->matchstring(), "[ literal word1 ]", "prepare $question");

    $question = "'and' or word1";
    $query->prepare($question);
    ok($query->matchstring(), "[ or [ literal and ] [ literal word1 ] ]", "prepare $question");

    $question = "\"and\" or word1";
    $query->prepare($question);
    ok($query->matchstring(), "[ or [ literal and ] [ literal word1 ] ]", "prepare $question");

    $question = "word1 or word2";
    $query->prepare($question);
    ok($query->matchstring(), "[ or [ literal word1 ] [ literal word2 ] ]", "prepare $question");

    $question = "word1 and word2";
    $query->prepare($question);
    ok($query->matchstring(), "[ and [ literal word1 ] [ literal word2 ] ]", "prepare $question");

    $question = "word1 near word2";
    $query->prepare($question);
    ok($query->matchstring(), "[ near [ literal word1 ] [ literal word2 ] ]", "prepare $question");

    $question = "not word1";
    $query->prepare($question);
    ok($query->matchstring(), "[ not [ literal word1 ] ]", "prepare $question");

    $question = "scope1: word1";
    $query->prepare($question);
    ok($query->matchstring(), "[ scope 'scope1' [ literal word1 ] ]", "prepare $question");
    
    $question = "word1 word2";
    $query->prepare($question);
    ok($query->matchstring(), "[ literal word1 word2 ]", "prepare $question");

    $question = "(word1) (word2)";
    $query->prepare($question);
    ok($query->matchstring(), "[ concat [ literal word1 ] [ literal word2 ] ]", "prepare $question");

    $question = "word1 or word2 and word3";
    $query->prepare($question);
    ok($query->matchstring(), "[ or [ literal word1 ] [ and [ literal word2 ] [ literal word3 ] ] ]", "prepare $question");

    $question = "(word1 or word2) and word3";
    $query->prepare($question);
    ok($query->matchstring(), "[ and [ or [ literal word1 ] [ literal word2 ] ] [ literal word3 ] ]", "prepare $question");

    $question = "word1 and not word2";
    $query->prepare($question);
    ok($query->matchstring(), "[ and [ literal word1 ] [ not [ literal word2 ] ] ]", "prepare $question");

    $question = "scope1: ( word1 and word2 or scope2: word3 ) or word4";
    $query->prepare($question);
    ok($query->matchstring(), "[ or [ scope 'scope1' [ or [ and [ literal word1 ] [ literal word2 ] ] [ scope 'scope2' [ literal word3 ] ] ] ] [ literal word4 ] ]", "prepare $question");

}

#
# ParseAdvanced parameters
#
{
    my($question) = "word1 et word2 ou word3 et non word4 proche word5 et 'word6' et scope1: word7 et scope2: word8";
    my($query) = Text::Query->new($question,
				  -operators => {
				      'or' => 'ou',
				      'and' => 'et',
				      'near' => 'proche',
				      'not' => 'non',
				  },
				  -scope_map => {
				      'scope1' => 'scopeother',
				  },
				  -quotes => '"',
				  -parse => 'Text::Query::ParseAdvanced',
                                  -build => 'Text::Query::Build',
				  -verbose => 0);
    ok($query->matchstring(), "[ or [ and [ literal word1 ] [ literal word2 ] ] [ and [ and [ and [ and [ literal word3 ] [ near [ not [ literal word4 ] ] [ literal word5 ] ] ] [ literal 'word6' ] ] [ scope 'scopeother' [ literal word7 ] ] ] [ scope 'scope2' [ literal word8 ] ] ] ]", "prepare $question");
}

# Local Variables: ***
# mode: perl ***
# End: ***
