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

# a form feed after nothing but sequences is at the beginning
$fold->configure(text => "\e[31m\f\e[m", width => 10);
is_deeply(chops($fold),
	  [ "\e[31m\f\e[m" ],
	  "formfeed in a color");

$fold->configure(text => "\e[31m\fb\e[m", width => 10);
is_deeply(chops($fold),
	  [ "\e[31m\fb\e[m" ],
	  "formfeed in a color, with text");

$fold->configure(text => "a\e[31mb\fc\e[m", width => 10);
is_deeply(chops($fold),
	  [ "a\e[31mb\e[m", "\e[31m\fc\e[m" ],
	  "formfeed in the middle of a color");

$fold->configure(text => "a\e[31m\e[m\fb", width => 10);
is_deeply(chops($fold),
	  [ "a\e[31m\e[m", "\fb" ],
	  "formfeed after text and sequences");

{
    use Text::ANSI::Fold qw(ansi_fold);
    my @r = ansi_fold "\e[31m\f\e[m", -1, expand => 1;
    is_deeply([ @r[0,1] ], [ "\e[31m\f\e[m", "" ],
	      "formfeed in a color, unlimited width");
}

done_testing;
