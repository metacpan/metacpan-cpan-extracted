use strict;

package main;

use Test;

use Text::Query;

plan test => 21;

#
# ParseSimple logic
#
{
    my($question);
    my($query) = Text::Query->new('blurk',
				  -build => 'Text::Query::BuildSQLMySQL',
				  -fields_searched => 'field1',
				  );

    $question = "10";
    $query->prepare($question);
    ok($query->matchstring(), " ( field1 regexp '[[:<:]]10[[:>:]]' ) ", "prepare $question");

    $question = "+10 +20";
    $query->prepare($question);
    ok($query->matchstring(), " (  ( field1 regexp '[[:<:]]10[[:>:]]' and field1 regexp '[[:<:]]20[[:>:]]' )  ) ", "prepare $question");

    $question = "+10 20 -30";
    $query->prepare($question);
    ok($query->matchstring(), " (  ( field1 regexp '[[:<:]]10[[:>:]]' and  not (  ( field1 regexp '[[:<:]]30[[:>:]]' )  )  and  ( field1 regexp '[[:<:]]20[[:>:]]' )  )  ) ", "prepare $question");

    $question = "+10 20 -30 +'40 50' -60 70";
    $query->prepare($question);
    ok($query->matchstring(), " (  ( field1 regexp '[[:<:]]10[[:>:]]' and field1 regexp '[[:<:]]40 50[[:>:]]' and  not (  ( field1 regexp '[[:<:]]30[[:>:]]' or field1 regexp '[[:<:]]60[[:>:]]' )  )  and  ( field1 regexp '[[:<:]]20[[:>:]]' or field1 regexp '[[:<:]]70[[:>:]]' )  )  ) ", "prepare $question");

}

#
# ParseAdvanced logic
#
{
    my($question);
    my($query) = Text::Query->new('blurk',
				  -parse => 'Text::Query::ParseAdvanced',
				  -build => 'Text::Query::BuildSQLMySQL',
				  -fields_searched => 'field1',
				  );

    $question = "word1";
    $query->prepare($question);
    ok($query->matchstring(), " ( field1 regexp '[[:<:]][wW][oO][rR][dD]1[[:>:]]' ) ", "prepare $question");

    $question = "'and' or word1";
    $query->prepare($question);
    ok($query->matchstring(), " (  ( field1 regexp '[[:<:]][aA][nN][dD][[:>:]]' or field1 regexp '[[:<:]][wW][oO][rR][dD]1[[:>:]]' )  ) ", "prepare $question");

    $question = "\"and\" or word1";
    $query->prepare($question);
    ok($query->matchstring(), " (  ( field1 regexp '[[:<:]][aA][nN][dD][[:>:]]' or field1 regexp '[[:<:]][wW][oO][rR][dD]1[[:>:]]' )  ) ", "prepare $question");

    $question = "word1 or word2";
    $query->prepare($question);
    ok($query->matchstring(), " (  ( field1 regexp '[[:<:]][wW][oO][rR][dD]1[[:>:]]' or field1 regexp '[[:<:]][wW][oO][rR][dD]2[[:>:]]' )  ) ", "prepare $question");

    $question = "word1 and word2";
    $query->prepare($question);
    ok($query->matchstring(), " (  ( field1 regexp '[[:<:]][wW][oO][rR][dD]1[[:>:]]' and field1 regexp '[[:<:]][wW][oO][rR][dD]2[[:>:]]' )  ) ", "prepare $question");

    $question = "word1 near word2";
    $query->prepare($question);
    ok($query->matchstring(), " ( field1 regexp '[[:<:]]([wW][oO][rR][dD]1([[:space:]]+[[:alnum:]]+){0,10}[[:space:]]+[wW][oO][rR][dD]2)|([wW][oO][rR][dD]2([[:space:]]+[[:alnum:]]+){0,10}[[:space:]]+[wW][oO][rR][dD]1)[[:>:]]' ) ", "prepare $question");

    $question = "not word1";
    $query->prepare($question);
    ok($query->matchstring(), " (  not ( field1 regexp '[[:<:]][wW][oO][rR][dD]1[[:>:]]' )  ) ", "prepare $question");

    $question = "scope1: word1";
    $query->prepare($question);
    ok($query->matchstring(), " ( scope1 regexp '[[:<:]][wW][oO][rR][dD]1[[:>:]]' ) ", "prepare $question");
    
    $question = "word1 word2";
    $query->prepare($question);
    ok($query->matchstring(), " ( field1 regexp '[[:<:]][wW][oO][rR][dD]1 [wW][oO][rR][dD]2[[:>:]]' ) ", "prepare $question");

    $question = "(word1) (word2)";
    $query->prepare($question);
    ok($query->matchstring(), " ( field1 regexp '[[:<:]][wW][oO][rR][dD]1 [wW][oO][rR][dD]2[[:>:]]' ) ", "prepare $question");

    $question = "word1 or word2 and word3";
    $query->prepare($question);
    ok($query->matchstring(), " (  ( field1 regexp '[[:<:]][wW][oO][rR][dD]1[[:>:]]' or  ( field1 regexp '[[:<:]][wW][oO][rR][dD]2[[:>:]]' and field1 regexp '[[:<:]][wW][oO][rR][dD]3[[:>:]]' )  )  ) ", "prepare $question");

    $question = "(word1 or word2) and word3";
    $query->prepare($question);
    ok($query->matchstring(), " (  (  ( field1 regexp '[[:<:]][wW][oO][rR][dD]1[[:>:]]' or field1 regexp '[[:<:]][wW][oO][rR][dD]2[[:>:]]' )  and field1 regexp '[[:<:]][wW][oO][rR][dD]3[[:>:]]' )  ) ", "prepare $question");

    $question = "word1 and not word2";
    $query->prepare($question);
    ok($query->matchstring(), " (  ( field1 regexp '[[:<:]][wW][oO][rR][dD]1[[:>:]]' and  not ( field1 regexp '[[:<:]][wW][oO][rR][dD]2[[:>:]]' )  )  ) ", "prepare $question");

    $question = "scope1: ( word1 and word2 or scope2: word3 ) or word4";
    $query->prepare($question);
    ok($query->matchstring(), " (  (  ( scope1 regexp '[[:<:]][wW][oO][rR][dD]1[[:>:]]' and scope1 regexp '[[:<:]][wW][oO][rR][dD]2[[:>:]]' )  or scope2 regexp '[[:<:]][wW][oO][rR][dD]3[[:>:]]' or field1 regexp '[[:<:]][wW][oO][rR][dD]4[[:>:]]' )  ) ", "prepare $question");

    $question = "field2: ( 20 and 21 or field1: 21 ) or field1: 100 or 'field2:' and 30 near 40";
    $query->prepare($question);
    ok($query->matchstring(), " (  (  (  ( field2 regexp '[[:<:]]20[[:>:]]' and field2 regexp '[[:<:]]21[[:>:]]' )  or field1 regexp '[[:<:]]21[[:>:]]' )  or field1 regexp '[[:<:]]100[[:>:]]' or  ( field1 regexp '[[:<:]][fF][iI][eE][lL][dD]2:[[:>:]]' and field1 regexp '[[:<:]](30([[:space:]]+[[:alnum:]]+){0,10}[[:space:]]+40)|(40([[:space:]]+[[:alnum:]]+){0,10}[[:space:]]+30)[[:>:]]' )  )  ) ", "prepare $question");

    $question = "field2,field3: ( 20 and 21 )";
    $query->prepare($question);
    ok($query->matchstring(), " ( (  ( field2 regexp '[[:<:]]20[[:>:]]' and field2 regexp '[[:<:]]21[[:>:]]' )  ) or (  ( field3 regexp '[[:<:]]20[[:>:]]' and field3 regexp '[[:<:]]21[[:>:]]' )  ) ) ", "prepare $question");

    $question = "20 and 21";
    $query->prepare($question, -fields_searched => 'field2,field3');
    ok($query->matchstring(), " ( (  ( field2 regexp '[[:<:]]20[[:>:]]' and field2 regexp '[[:<:]]21[[:>:]]' )  ) or (  ( field3 regexp '[[:<:]]20[[:>:]]' and field3 regexp '[[:<:]]21[[:>:]]' )  ) ) ", "prepare $question");

}

# Local Variables: ***
# mode: perl ***
# End: ***
