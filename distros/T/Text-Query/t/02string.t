use strict;

package main;

use Test;

use Text::Query;

plan test => 56;

# Adapt to Perl 5.14+ regular expression stringification changes (see perlre docs)
my $re_flags = ($] >= 5.014) ? '?^s:' : '?s-xim:';

#
# ParseSimple logic
#
if ($]>=5.005)
{
    my($question);
    my($query) = Text::Query->new('bluf',
				  -build => 'Text::Query::BuildSimpleString',
				  -solve => 'Text::Query::SolveSimpleString',
				  -verbose => 0,
				  );

    $question = "word1";
    $query->prepare($question);
    ok($query->matchstring(), "($re_flags(?i)word1(?{[-1,1]}))", "prepare $question");
    ok($query->match("take my word1bla pal"), 1, "solve match $question");
    ok($query->match("take my lies pal"), 0, "solve no match $question");

    $question = "+word1 +word2";
    $query->prepare($question);
    ok($query->matchstring(), "($re_flags(?i)word1(?{[-2,1]})|word2(?{[-3,1]}))", "prepare $question");
    ok($query->match("take word2 my word1 and pal"), 2, "solve match $question");
    ok($query->match("take my lies word2 pal"), 0, "solve no match $question");

    $question = "+word1 word2 -word3";
    $query->prepare($question);
    ok($query->matchstring(), "($re_flags(?i)word1(?{[-2,1]})|word2(?{[-1,1]})|word3(?{[0,1]}))", "prepare $question");
    ok($query->match("take my word1 and word2 pal"), 2, "solve match 1 $question");
    ok($query->match("take my word1 pal"), 1, "solve match 2 $question");
    ok($query->match("take word1 my word1 pal"), 2, "solve match 3 $question");
    ok($query->match("take word3 my word1 pal"), 0, "solve no match 1 $question");
    ok($query->match("take my lies word1 word2 word3 pal"), 0, "solve no match 2 $question");

    #
    # Try options
    #
    $question = "word1 word2";
    $query->prepare($question, -whole => 1);
    ok($query->matchstring(), "($re_flags(?i)" . '\bword1\b(?{[-1,1]})|\bword2\b(?{[-1,1]}))', "prepare $question");
    ok($query->match("take my Word1 and Word2 pal"), 2, "solve match $question");
    ok($query->match("take my word1flux word2blux pal"), 0, "solve no match $question");

    # This does not work properly $question = 'word\d+' + is an operator ...
    $question = 'word\d*';
    $query->prepare($question, -regexp => 1, -whole => 1);
    ok($query->matchstring(), "($re_flags(?i)" . '(?:\bword\d*\b)(?{[-1,1]}))', "prepare $question");
    ok($query->match("take my word1 and word2 pal"), 2, "solve match $question");
    ok($query->match("take my word1flux word2blux pal"), 0, "solve no match $question");
    
    $question = "word1 word2";
    $query->prepare($question, -case => 1, -whole => 0, -regexp => 0);
    ok($query->matchstring(), "(${re_flags}word1(?{[-1,1]})|word2(?{[-1,1]}))", "prepare $question");
    ok($query->match("take my word1 and word2 pal"), 2, "solve match $question");
    ok($query->match("take my Word1 And Word2 pal"), 0, "solve no match $question");

    $question = 'word1\ word2';
    $query->prepare($question, -litspace => 1, -case => 0);
    ok($query->matchstring(), "($re_flags(?i)" . 'word1\\\\\ word2(?{[-1,1]}))', "prepare $question");
    ok($query->match("take my word1\\ word2 pal"), 1, "solve match $question");
    ok($query->match("take my word1    word2 pal"), 0, "solve no match $question");

    #
    # Try variants of match and matchscalar
    #
    $question = "word1";
    $query->prepare($question);
    ok($query->matchscalar("take my word1 pal"), 1, "solve match $question");
    $_ = "take my word1 pal";
    ok($query->matchscalar(), 1, "solve match $question");
    $_ = '';
    my(@f) = $query->match(["word1"], ["word2 word1"], ["word3 word1"], ["word3"]);
    ok(join("", map { "$_->[0] => $_->[1] " } @f), "word1 => 1 word2 word1 => 1 word3 word1 => 1 word3 => 0 ", "solve match $question");
    @f = $query->match("word1", "word2 word1", "word3 word1", "word3");
    ok(join("", map { "$_->[0] => $_->[1] " } @f), "word1 => 1 word2 word1 => 1 word3 word1 => 1 word3 => 0 ", "solve match $question");
    @f = $query->match(["word1", "word2 word1", "word3 word1", "word3"]);
    ok(join("", map { "$_->[0] => $_->[1] " } @f), "word1 => 1 word2 word1 => 1 word3 word1 => 1 word3 => 0 ", "solve match $question");
}

#
# ParseAdvanced logic
#
{
    my($question);
    my($query) = Text::Query->new('bluf', -verbose => 0);
    $query->configure(-parse => 'Text::Query::ParseAdvanced',
		      -solve => 'Text::Query::SolveAdvancedString',
		      -build => 'Text::Query::BuildAdvancedString');

    $question = "word1";
    $query->prepare($question);
    ok($query->matchstring(), "(?i)(?:word1)", "prepare $question");
    ok($query->match("take my word1 pal"), 1, "solve match $question");
    ok($query->match("take my pal"), '', "solve no match $question");

    $question = "'and' or word1";
    $query->prepare($question);
    ok($query->matchstring(), "(?i)(?:and|word1)", "prepare $question");
    ok($query->match("take my word1 pal and"), 1, "solve match $question");

    $question = "\"and\" or word1";
    $query->prepare($question);
    ok($query->matchstring(), "(?i)(?:and|word1)", "prepare $question");

    $question = "word1 or word2";
    $query->prepare($question);
    ok($query->matchstring(), "(?i)(?:word1|word2)", "prepare $question");
    ok($query->match("take my word1 pal and"), 1, "solve match $question");

    $question = "word1 and word2";
    $query->prepare($question);
    ok($query->matchstring(), "(?i)(?:^(?=.*word1)(?=.*word2))", "prepare $question");
    ok($query->match("take my word1 pal word2 and"), 1, "solve match $question");
    ok($query->match("take my word2 pal"), '', "solve no match $question");

    $question = "word1 near word2";
    $query->prepare($question);
    ok($query->matchstring(), '(?i)(?:(?:word1\s*(?:\S+\s+){0,10}word2)|(?:word2\s*(?:\S+\s+){0,10}word1))', "prepare $question");
    ok($query->match("take my word1 space1 space2 word2 pal"), 1, "solve match $question");
    ok($query->match("take my word1 space space space space space space space space space space space space space space space word2 pal"), '', "solve no match $question");

    $question = "not word1";
    $query->prepare($question);
    ok($query->matchstring(), '(?i)(?:(?:^(?:(?!word1).)*$))', "prepare $question");
    ok($query->match("take my pal"), 1, "solve match $question");
    ok($query->match("take my word1 pal"), '', "solve no match $question");

    $question = "scope1: word1";
    $query->prepare($question);
    ok($query->matchstring(), '(?i)(?:word1)', "prepare $question");
    
    $question = "word1 word2";
    $query->prepare($question);
    ok($query->matchstring(), '(?i)(?:word1\s+word2)', "prepare $question");
    ok($query->match("take my word1 \tword2 pal"), 1, "solve match $question");

    $question = "(word1) (word2)";
    $query->prepare($question);
    ok($query->matchstring(), '(?i)(?:(?:(?:word1)\s*(?:word2)))', "prepare $question");
    ok($query->match("take my word1word2 pal"), 1, "solve match $question");
    ok($query->match("take my word1    word2 pal"), 1, "solve match $question");

    $question = "word1 or word2 and word3";
    $query->prepare($question);
    ok($query->matchstring(), '(?i)(?:word1|^(?=.*word2)(?=.*word3))', "prepare $question");

    $question = "(word1 or word2) and word3";
    $query->prepare($question);
    ok($query->matchstring(), '(?i)(?:^(?=.*(?:word1|word2))(?=.*word3))', "prepare $question");

    $question = "word1 and not word2";
    $query->prepare($question);
    ok($query->matchstring(), '(?i)(?:^(?=.*word1)(?=.*(?:^(?:(?!word2).)*$)))', "prepare $question");

    $question = "scope1: ( word1 and word2 or scope2: word3 ) or word4";
    $query->prepare($question);
    ok($query->matchstring(), '(?i)(?:(?:^(?=.*word1)(?=.*word2)|word3)|word4)', "prepare $question");

}

# Local Variables: ***
# mode: perl ***
# End: ***
