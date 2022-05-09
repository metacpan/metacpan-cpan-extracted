use strict;
use warnings;
use utf8;

use Test::More tests => 32;
use Text::Amuse::Preprocessor::TypographyFilters;

sub check_link {
    my ($in, $out, $comment) = @_;
    my $got = Text::Amuse::Preprocessor::TypographyFilters::linkify($in);
    is $got, $out, $comment;
    is Text::Amuse::Preprocessor::TypographyFilters::linkify($got), $out, "Round trip ok";
    diag $in;
    diag $got;
}

check_link("Retrieved on February 2, 2011 from http://j12.org/spunk/library/writers/meltzer/sp001500.html",
           "Retrieved on February 2, 2011 from [[http://j12.org/spunk/library/writers/meltzer/sp001500.html][j12.org]]",
           "checking linkifier");

check_link("Retrieved on December 22, 2011 from http://libertarian-labyrinth.org/archive/The_Great_Debacle",
           "Retrieved on December 22, 2011 from [[http://libertarian-labyrinth.org/archive/The_Great_Debacle][libertarian-labyrinth.org]]",
           "checking linkifier 2");

check_link("<br>http://www.nancho.net/advisors/anaes.html<br>",
           "<br>[[http://www.nancho.net/advisors/anaes.html][www.nancho.net]]<br>",
           "Checking linkifier 3");

check_link("http://www.nancho.net/advisors/anaes.html<br>http://www.nancho.net/advisors/anaes.html<br>",
           "[[http://www.nancho.net/advisors/anaes.html][www.nancho.net]]<br>[[http://www.nancho.net/advisors/anaes.html][www.nancho.net]]<br>",
           "Checking linkifier 4");

check_link(" https://web.archive.org/web/20220504202253/https://amusewiki.org/special/index ",
           " [[https://web.archive.org/web/20220504202253/https://amusewiki.org/special/index][web.archive.org]] ",
           "link interpolated"
          );
check_link(" [[https://web.archive.org/web/20220504202253/https://amusewiki.org/special/index][web.archive.org]] ",
           " [[https://web.archive.org/web/20220504202253/https://amusewiki.org/special/index][web.archive.org]] ",
           "link left alone (already parsed)"
          );

check_link("http://test.org/xx and http://test.org/xx",
           '[[http://test.org/xx][test.org]] and [[http://test.org/xx][test.org]]'
          );
check_link('[[http://test.org/xx][test.org]] and [[http://test.org/xx][test.org]]',
           '[[http://test.org/xx][test.org]] and [[http://test.org/xx][test.org]]');

check_link('http://test.org/xx and [[http://test.org/xx][test.org]]',
           '[[http://test.org/xx][test.org]] and [[http://test.org/xx][test.org]]');

check_link('http://test.org/xx and http://test.org/xx][test.org]] ',
           '[[http://test.org/xx][test.org]] and http://test.org/xx][test.org]] ');

check_link('<http://test.org/xx> and >http://test.org/xx<',
           '<[[http://test.org/xx][test.org]]> and >[[http://test.org/xx][test.org]]<');


check_link('<http://test.org/xx> and https://test.org:80/>http://test.org/xx< and https://test.org/ and [[https://test.org/][test.org]]',
           '<[[http://test.org/xx][test.org]]> and [[https://test.org:80/][test.org]]>[[http://test.org/xx][test.org]]< and [[https://test.org/][test.org]] and [[https://test.org/][test.org]]');

check_link('https://example.com/@test and https://example.com/@test',
           '[[https://example.com/@test][example.com]] and [[https://example.com/@test][example.com]]'
          );

check_link("(http://en.wikipedia.org/wiki/Pi_%28instrument%29)",
           '([[http://en.wikipedia.org/wiki/Pi_%28instrument%29][en.wikipedia.org]])');


check_link("(http://en.wikipedia.org?test=1)",
           '([[http://en.wikipedia.org?test=1][en.wikipedia.org]])');


check_link("(http://en.wikipedia.org?test=1&test=2) (http://en.wikipedia.org/test?test=1)",
           '([[http://en.wikipedia.org?test=1&test=2][en.wikipedia.org]]) ([[http://en.wikipedia.org/test?test=1][en.wikipedia.org]])');
