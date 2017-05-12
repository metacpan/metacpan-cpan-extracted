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
				  -build => 'Text::Query::BuildSQLPg',
				  -fields_searched => 'field1',
				  );

    $question = "10";
    $query->prepare($question);
    ok($query->matchstring(), " ( field1 ~* '[[:<:]]10[[:>:]]' ) ", "prepare $question");

    $question = "+10 +20";
    $query->prepare($question);
    ok($query->matchstring(), " (  ( field1 ~* '[[:<:]]10[[:>:]]' and field1 ~* '[[:<:]]20[[:>:]]' )  ) ", "prepare $question");
						
    $question = "+10 20 -30";
    $query->prepare($question);
    ok($query->matchstring(), " (  ( field1 ~* '[[:<:]]10[[:>:]]' and not ( ( field1 ~* '[[:<:]]30[[:>:]]' ) ) and  ( field1 ~* '[[:<:]]20[[:>:]]' or field1 ~* '[[:<:]]10[[:>:]]' )  )  ) ", "prepare $question");

    $question = "+10 20 -30 +'40 50' -60 70";
    $query->prepare($question);
    ok($query->matchstring(), " (  ( field1 ~* '[[:<:]]10[[:>:]]' and field1 ~* '[[:<:]]40 50[[:>:]]' and not ( ( field1 ~* '[[:<:]]30[[:>:]]' or field1 ~* '[[:<:]]60[[:>:]]' ) ) and  ( field1 ~* '[[:<:]]20[[:>:]]' or field1 ~* '[[:<:]]70[[:>:]]' or field1 ~* '[[:<:]]10[[:>:]]' )  )  ) ", "prepare $question");

}

#
# ParseAdvanced logic
#
{
    my($question);
    my($query) = Text::Query->new('blurk',
				  -parse => 'Text::Query::ParseAdvanced',
				  -build => 'Text::Query::BuildSQLPg',
				  -fields_searched => 'field1',
				  );

    $question = "word1";
    $query->prepare($question);
    ok($query->matchstring(), " ( field1 ~* '[[:<:]]word1[[:>:]]' ) ", "prepare $question");

    $question = "'and' or word1";
    $query->prepare($question);
    ok($query->matchstring(), " (  ( field1 ~* '[[:<:]]and[[:>:]]' or field1 ~* '[[:<:]]word1[[:>:]]' )  ) ", "prepare $question");

    $question = "\"and\" or word1";
    $query->prepare($question);
    ok($query->matchstring(), " (  ( field1 ~* '[[:<:]]and[[:>:]]' or field1 ~* '[[:<:]]word1[[:>:]]' )  ) ", "prepare $question");

    $question = "word1 or word2";
    $query->prepare($question);
    ok($query->matchstring(), " (  ( field1 ~* '[[:<:]]word1[[:>:]]' or field1 ~* '[[:<:]]word2[[:>:]]' )  ) ", "prepare $question");

    $question = "word1 and word2";
    $query->prepare($question);
    ok($query->matchstring(), " (  ( field1 ~* '[[:<:]]word1[[:>:]]' and field1 ~* '[[:<:]]word2[[:>:]]' )  ) ", "prepare $question");

    $question = "word1 near word2";
    $query->prepare($question);
    ok($query->matchstring(), " ( field1 ~* '[[:<:]]word1[^a-z0-9]{0,10}word2[[:>:]]' ) ", "prepare $question");

    $question = "not word1";
    $query->prepare($question);
    ok($query->matchstring(), " ( not (field1 ~* '[[:<:]]word1[[:>:]]') ) ", "prepare $question");

    $question = "scope1: word1";
    $query->prepare($question);
    ok($query->matchstring(), " ( scope1 ~* '[[:<:]]word1[[:>:]]' ) ", "prepare $question");
    
    $question = "word1 word2";
    $query->prepare($question);
    ok($query->matchstring(), " ( field1 ~* '[[:<:]]word1 word2[[:>:]]' ) ", "prepare $question");

    $question = "(word1) (word2)";
    $query->prepare($question);
    ok($query->matchstring(), " ( field1 ~* '[[:<:]]word1 word2[[:>:]]' ) ", "prepare $question");

    $question = "word1 or word2 and word3";
    $query->prepare($question);
    ok($query->matchstring(), " (  ( field1 ~* '[[:<:]]word1[[:>:]]' or  ( field1 ~* '[[:<:]]word2[[:>:]]' and field1 ~* '[[:<:]]word3[[:>:]]' )  )  ) ", "prepare $question");

    $question = "(word1 or word2) and word3";
    $query->prepare($question);
    ok($query->matchstring(), " (  (  ( field1 ~* '[[:<:]]word1[[:>:]]' or field1 ~* '[[:<:]]word2[[:>:]]' )  and field1 ~* '[[:<:]]word3[[:>:]]' )  ) ", "prepare $question");

    $question = "word1 and not word2";
    $query->prepare($question);
    ok($query->matchstring(), " (  ( field1 ~* '[[:<:]]word1[[:>:]]' and not (field1 ~* '[[:<:]]word2[[:>:]]') )  ) ", "prepare $question");

    $question = "scope1: ( word1 and word2 or scope2: word3 ) or word4";
    $query->prepare($question);
    ok($query->matchstring(), " (  (  ( scope1 ~* '[[:<:]]word1[[:>:]]' and scope1 ~* '[[:<:]]word2[[:>:]]' )  or scope2 ~* '[[:<:]]word3[[:>:]]' or field1 ~* '[[:<:]]word4[[:>:]]' )  ) ", "prepare $question");

    $question = "field2: ( 20 and 21 or field1: 21 ) or field1: 100 or 'field2:' and 30 near 40";
    $query->prepare($question);
    ok($query->matchstring(), " (  (  (  ( field2 ~* '[[:<:]]20[[:>:]]' and field2 ~* '[[:<:]]21[[:>:]]' )  or field1 ~* '[[:<:]]21[[:>:]]' )  or field1 ~* '[[:<:]]100[[:>:]]' or  ( field1 ~* '[[:<:]]field2:[[:>:]]' and field1 ~* '[[:<:]]30[^a-z0-9]{0,10}40[[:>:]]' )  )  ) ", "prepare $question");

    $question = "field2,field3: ( 20 and 21 )";
    $query->prepare($question);
    ok($query->matchstring(), " (  ( ( ( field2 ~* '[[:<:]]20[[:>:]]' ) or ( field3 ~* '[[:<:]]20[[:>:]]' ) ) and ( ( field2 ~* '[[:<:]]21[[:>:]]' ) or ( field3 ~* '[[:<:]]21[[:>:]]' ) ) )  ) ", "prepare $question");

    $question = "20 and 21";
    $query->prepare($question, -fields_searched => 'field2,field3');
    ok($query->matchstring(), " (  ( ( ( field2 ~* '[[:<:]]20[[:>:]]' ) or ( field3 ~* '[[:<:]]20[[:>:]]' ) ) and ( ( field2 ~* '[[:<:]]21[[:>:]]' ) or ( field3 ~* '[[:<:]]21[[:>:]]' ) ) )  ) ", "prepare $question");

}

# Local Variables: ***
# mode: perl ***
# End: ***
