use v5.14;
use warnings;
use utf8;
use open IO => 'utf8', ':std';
use Test::More 0.98;

use Text::ANSI::Fold ':constants';

sub fold_trim {
    my($text, %opt) = @_;
    my $fold = Text::ANSI::Fold->new(
	linebreak => LINEBREAK_ALL, trim => 1, %opt);
    [ $fold->fold($text) ];
}

# folded, rest
is_deeply(
    [ Text::ANSI::Fold->new(width => 10, linebreak => LINEBREAK_ALL)
      ->fold("aaaa bbbbb cccc") ],
    [ "aaaa bbbbb ", "cccc", 11 ],
    "off by default: the space stays");

is_deeply(fold_trim("aaaa bbbbb cccc", width => 10),
	  [ "aaaa bbbbb", "cccc", 10 ], "space ran in");
is_deeply(fold_trim("aaaa bbbb, cccc", width => 9),
	  [ "aaaa bbbb,", "cccc", 10 ], "the comma stays, the space goes");
is_deeply(fold_trim("aaaa bbbbb cccc", width => 10, padding => 1),
	  [ "aaaa bbbbb", "cccc", 10 ], "padding does not overflow");
is_deeply(fold_trim("aaaa bbbb cccc", width => 7, boundary => 'word'),
	  [ "aaaa", "bbbb cccc", 4 ], "space before the word boundary");
is_deeply(fold_trim("aaaa bbbb cccc", width => 7, boundary => 'word', padding => 1),
	  [ "aaaa   ", "bbbb cccc", 4 ], "padded after it is removed");
is_deeply(fold_trim("あいう　えお", width => 6),
	  [ "あいう　", "えお", 8 ], "full-width space stays");

is_deeply(fold_trim("あいうえお", width => 5, splitwide => 1, linebreak => LINEBREAK_NONE),
	  [ "あい\x{a0}", "\x{a0}えお", 5 ], "filler of splitwide stays");
is_deeply(fold_trim("aaaa\x{a0} bbbb", width => 6),
	  [ "aaaa\x{a0}", "bbbb", 5 ], "no-break space stays");

is_deeply(fold_trim("aaaa bbbbb \n", width => 20),
	  [ "aaaa bbbbb \n", "", 11 ], "end of the line is not a fold");
is_deeply(fold_trim("aaaa bbbbb ", width => 20),
	  [ "aaaa bbbbb ", "", 11 ], "end of the text is not a fold");
is_deeply(fold_trim("aaaaaaaaaa \nbbb", width => 10),
	  [ "aaaaaaaaaa ", "\nbbb", 11 ], "space ran in before the newline");

my $r = fold_trim("\e[41maaaa bbbbb cccc\e[m", width => 10);
is($r->[0], "\e[41maaaa bbbbb \e[m", "colored space stays");
$r = fold_trim("\e[41maaaa bbbbb\e[m cccc", width => 10);
is($r->[0], "\e[41maaaa bbbbb\e[m", "plain space after the color goes");

my $fold = Text::ANSI::Fold->new(
    width => 10, linebreak => LINEBREAK_ALL, trim => 1,
    text => "aaaa bbbbb cccc ddddd eeee",
    );
my @lines;
while (length(my $l = $fold->retrieve)) { push @lines, $l }
is_deeply(\@lines, [ "aaaa bbbbb", "cccc ddddd", "eeee" ], "retrieve")
    or diag explain \@lines;

done_testing;
