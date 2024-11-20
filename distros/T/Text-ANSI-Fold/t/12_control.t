use strict;
use Test::More 0.98;
use utf8;

use Text::ANSI::Fold;

my $fold = Text::ANSI::Fold->new;

sub chops {
    my $obj = shift;
    [ $fold->chops(@_) ];
}

$fold->configure(text => "1234567890\n1234567890\n", width => 5);
is_deeply(chops($fold),
	  [ "12345", "67890\n", "12345", "67890\n" ],
	  "newline");

$fold->configure(text => "1234567890\r\n1234567890\r\n", width => 5);
is_deeply(chops($fold),
	  [ "12345", "67890\r\n", "12345", "67890\r\n" ],
	  "cr/nl");

$fold->configure(text => "1234567890\x{00}1234567890\N{U+2028}1234567890\N{U+2029}", width => 5);
is_deeply(chops($fold),
	  [ "12345", "67890\0", "12345", "67890\N{U+2028}", "12345", "67890\N{U+2029}" ],
	  "null and line/paragraph separator (just)");

$fold->configure(text => "1234567890\x{00}1234567890\N{U+2028}1234567890\N{U+2029}", width => 20);
is_deeply(chops($fold),
	  [ "1234567890\0", "1234567890\N{U+2028}", "1234567890\N{U+2029}" ],
	  "null and line/paragraph separator (long)");

$fold->configure(text => "\n\0\n\n\N{U+2028}\n\n\N{U+2029}\n", width => 5);
is_deeply(chops($fold),
	  [ "\n", "\0", "\n", "\n", "\N{U+2028}", "\n", "\n", "\N{U+2029}", "\n" ],
	  "newline & null, line/paragraph separator");

$fold->configure(text => "a\rb", width => 5);
is_deeply(chops($fold),
	  [ "a\rb" ],
	  "cr");

$fold->configure(text => "12345\r6789012345", width => 5);
is_deeply(chops($fold),
	  [ "12345\r67890", "12345" ],
	  "cr @ width position");

$fold->configure(text => "a\n\fb", width => 10);
is_deeply(chops($fold),
	  [ "a\n", "\fb" ],
	  "formfeed at tol");

$fold->configure(text => "a\fb", width => 10);
is_deeply(chops($fold),
	  [ "a", "\fb" ],
	  "formfeed in the middle");

done_testing;
