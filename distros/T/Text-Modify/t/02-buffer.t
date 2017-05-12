#!/usr/bin/perl -w

use strict;

use Test::More tests => 63;

use Text::Buffer;


# Turn off autonewline, for easier comparision
my $text = Text::Buffer->new(debug => 0, autonewline => "");

# Empty buffer tests
ok( $text, 'create empty buffer');
is( $text->getLineCount(), 0, 'empty line count'); 
is( $text->getLineNumber(), 1, 'line pos is 1 (even on empty buffer)' ); 
ok( $text->isEOF(), 'empty buffer is always EOF' );
ok( $text->isEmpty(), 'empty buffer is emtpy' );

ok( $text->insert("bar"), 'inserting bar' );
# insert increases the linecount, but should not alter curr linepos
is( $text->getLineCount(), 1, 'correct line count after insert' );
is( $text->get(), "bar", 'correct get after insert' );

# replace content of current line
ok( $text->set("foo"), 'set current line');
is( $text->get(), "foo", 'get after set');

is( $text->getLineNumber(), 1, 'correct line pos after insert' );
ok( $text->append("bar"), 'appending bar' );
# append should not alter the current position
is( $text->getLineNumber(), 1, 'correct line pos after append' );
is( $text->getLineCount(), 2, 'correct line count after insert' );
is( $text->get(), "foo", 'correct current line content after append' );

ok( $text->append("noone","wants","me" ), 'appending 3 lines' );
is( $text->getLineCount(), 5, 'count after array append' );

# Test navigation
is( $text->goto(3), 3, 'goto line 3' );
is( $text->get(), "noone", 'get content of line 3' );

is( $text->goto("-2"), 1, 'goto line 1 by -2' );
is( $text->get(), "foo", 'get content of current line' );
is( $text->goto("+3"), 4, 'goto line 4 by +3' );
is( $text->get(), "wants", 'get content of current line' );
is( $text->next(), "me", 'get next' );
is( $text->previous(2), "noone", 'get previous 2' );

my $linecount = $text->getLineCount();
is( $text->goto('top'), 1, 'goto top');
is( $text->goto('bottom'), $linecount, 'goto top');
is( $text->goto('start'), 1, 'goto top');
is( $text->goto('end'), $linecount, 'goto top');
is( $text->goto('first'), 1, 'goto top');
is( $text->goto('last'), $linecount, 'goto top');

# outofbounds checks, error handling
is( $text->goto(1000), undef, 'goto invalid pos');
ok( $text->getError() =~ /Invalid line position/i, 'correct error');
ok( !$text->getError(), 'error should be cleared after first get');

is( $text->goto(-1000), undef, 'goto invalid pos');
ok( $text->getError() =~ /Invalid line position/i, 'correct error');

is( $text->goto('blabla'), undef, 'goto invalid pos');
ok( $text->getError() =~ /Invalid line position/i, 'correct error');

# find tests
is($text->find("_nomatch_"), undef, "find no match");
is($text->find("bar",1), 2, "find bar");
is($text->findNext("bar"), undef, "find next bar");
is($text->find("me"), 5, "find next bar");

# TODO need more find tests, wrapping, also for wildcard & regex
TODO: {
    local $TODO = "Wilcard options not implemented";
    is( $text->find("*foo"), 2, "Wildcard find" );
    is( $text->findNext(), 5, "Wildcard find next" );
};

# replace tests
$text->goto(1);
### regex replacement tests here
ok($text->set("foo needs bar even if foo is a foobar"),'Create string for replace');
is($text->replace('foo','bar'),3,"replace foo with bar");
is($text->get(), "bar needs bar even if bar is a barbar", 'replaced string also ok');
$text->set("Noone lives in 127.0.0.1, rather on  10.10.10.10");
is($text->replaceRegex('(in|on)\s+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+','$1 localhost'),2,"replace regex (ip) replacecount");
is($text->get(),'Noone lives in localhost, rather on localhost',"replace regex result");
### string replacement tests here
$text->set("mybar/*bar is bar/*lish");
is($text->replaceString('bar/*','foo'),2,"replace plain string replacecount");
is($text->get(),'myfoobar is foolish',"replace plain string result");
### wildcard replacement tests here
$text->set("I go to /dev/null and drink /etc/more/beer from /dev/null/");
is($text->replaceWildcard('*null','/etc/pub'),2,"replace wildcard replacecount");
is($text->get(),'I go to /etc/pub and drink /etc/more/beer from /etc/pub/',"replace wildcard result");
$text->set("/dev/null or /dev/null or /etc/more/beer and /dev/null");
is($text->replaceWildcard('/*/null','/etc/pub'),3,"replace wildcard 2 replacecount");
is($text->get(),'/etc/pub or /etc/pub or /etc/more/beer and /etc/pub',"replace wildcard 2 result");


# save/load buffer tests
my $savefile = "save.tmp";
ok( $text->setAutoNewline('unix'), "set autonewline to unix");
is( $text->getAutoNewline(), "\n", "autonewline is unix");
ok( $text->save("$savefile"), 'save buffer' );
my $txtload = Text::Buffer->new(file => $savefile);
# FIXME should compare content instead
is( $txtload->getLineCount(), $text->getLineCount(), "saved and loaded equal");
ok(unlink($savefile),"remove tmpfile");

# Explicit tests of the helper functions
is( Text::Buffer->escapeRegexString("*bar(foo)"), '\\*bar\(foo\)', "escapeRegex class method");
is( Text::Buffer->escapeRegexString("a(b)c[d]+5.7\\=fun"), 'a\(b\)c\[d\]\+5\.7\\\\=fun', "escapeRegex class method");
is( Text::Buffer->convertWildcardToRegex("bar*foo"), 'bar.*foo', "convertWildcard class method");
