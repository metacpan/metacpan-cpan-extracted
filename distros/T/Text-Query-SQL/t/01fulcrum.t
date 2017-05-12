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
				  -build => 'Text::Query::BuildSQLFulcrum',
				  -fields_searched => 'field1',
				  );

    $question = "10";
    $query->prepare($question);
    ok($query->matchstring(), " (  field1 contains  '10'  ) ", "prepare $question");

    $question = "+10 +20";
    $query->prepare($question);
    ok($query->matchstring(), " (  field1 contains  (  '10'  &  '20'  )   ) ", "prepare $question");

    $question = "+10 20 -30";
    $query->prepare($question);
    ok($query->matchstring(), " (  field1 contains  (  '10' weight 10  &  ~ (  (  '30' weight 10  )  )  &  (  '20' weight 10  |  '10'  )  )   ) ", "prepare $question");

    $question = "+10 20 -30 +'40 50' -60 70";
    $query->prepare($question);
    ok($query->matchstring(), " (  field1 contains  (  '10' weight 10  &  '40 50' weight 10  &  ~ (  (  '30' weight 10  |  '60' weight 10  )  )  &  (  '20' weight 10  |  '70' weight 10  |  '10'  )  )   ) ", "prepare $question");

}

#
# ParseAdvanced logic
#
{
    my($question);
    my($query) = Text::Query->new('blurk',
				  -parse => 'Text::Query::ParseAdvanced',
				  -build => 'Text::Query::BuildSQLFulcrum',
				  -fields_searched => 'field1',
				  );

    $question = "word1";
    $query->prepare($question);
    ok($query->matchstring(), " (  field1 contains  'word1'  ) ", "prepare $question");

    $question = "'and' or word1";
    $query->prepare($question);
    ok($query->matchstring(), " (  field1 contains  (  'and'  |  'word1'  )   ) ", "prepare $question");

    $question = "\"and\" or word1";
    $query->prepare($question);
    ok($query->matchstring(), " (  field1 contains  (  'and'  |  'word1'  )   ) ", "prepare $question");

    $question = "word1 or word2";
    $query->prepare($question);
    ok($query->matchstring(), " (  field1 contains  (  'word1'  |  'word2'  )   ) ", "prepare $question");

    $question = "word1 and word2";
    $query->prepare($question);
    ok($query->matchstring(), " (  field1 contains  (  'word1'  &  'word2'  )   ) ", "prepare $question");

    $question = "word1 near word2";
    $query->prepare($question);
    ok($query->matchstring(), " (  field1 contains  proximity 10 characters (  'word1'  &  'word2'  )   ) ", "prepare $question");

    $question = "not word1";
    $query->prepare($question);
    ok($query->matchstring(), " (  field1 contains  ~ (  'word1'  )   ) ", "prepare $question");

    $question = "scope1: word1";
    $query->prepare($question);
    ok($query->matchstring(), " (  scope1 contains  'word1'  ) ", "prepare $question");
    
    $question = "word1 word2";
    $query->prepare($question);
    ok($query->matchstring(), " (  field1 contains  'word1 word2'  ) ", "prepare $question");

    $question = "(word1) (word2)";
    $query->prepare($question);
    ok($query->matchstring(), " (  field1 contains  'word1 word2'  ) ", "prepare $question");

    $question = "word1 or word2 and word3";
    $query->prepare($question);
    ok($query->matchstring(), " (  field1 contains  (  'word1'  |  (  'word2'  &  'word3'  )  )   ) ", "prepare $question");

    $question = "(word1 or word2) and word3";
    $query->prepare($question);
    ok($query->matchstring(), " (  field1 contains  (  (  'word1'  |  'word2'  )  &  'word3'  )   ) ", "prepare $question");

    $question = "word1 and not word2";
    $query->prepare($question);
    ok($query->matchstring(), " (  field1 contains  (  'word1'  &  ~ (  'word2'  )  )   ) ", "prepare $question");

    $question = "scope1: ( word1 and word2 or scope2: word3 ) or word4";
    $query->prepare($question);
    ok($query->matchstring(), " (  (  scope1 contains  (  'word1'  &  'word2'  )   or  scope2 contains  'word3'  or  field1 contains  'word4'  )  ) ", "prepare $question");

    $question = "field2: ( 20 and 21 or field1: 21 ) or field1: 100 or 'field2:' and 30 near 40";
    $query->prepare($question);
    ok($query->matchstring(), " (  (  (  field2 contains  (  '20'  &  '21'  )   or  field1 contains  '21'  )  or  field1 contains  '100'  or  (  field1 contains  'field2:'  and  field1 contains  proximity 10 characters (  '30'  &  '40'  )   )  )  ) ", "prepare $question");

    $question = "field2,field3: ( 20 and 21 )";
    $query->prepare($question);
    ok($query->matchstring(), " ( (  field2 contains  (  '20'  &  '21'  )   ) or (  field3 contains  (  '20'  &  '21'  )   ) ) ", "prepare $question");

    $question = "20 and 21";
    $query->prepare($question, -fields_searched => 'field2,field3');
    ok($query->matchstring(), " ( (  field2 contains  (  '20'  &  '21'  )   ) or (  field3 contains  (  '20'  &  '21'  )   ) ) ", "prepare $question");

}

# Local Variables: ***
# mode: perl ***
# End: ***
