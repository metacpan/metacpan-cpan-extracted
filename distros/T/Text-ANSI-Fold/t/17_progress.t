use v5.14;
use warnings;
use utf8;
use open IO => 'utf8', ':std';
use Test::More 0.98;

use Text::ANSI::Fold ':constants';

# fold the whole text, without the colors, or die
sub lines {
    my($text, %opt) = @_;
    my $fold = Text::ANSI::Fold->new(text => $text, %opt);
    my @lines;
    local $SIG{ALRM} = sub { die "timeout\n" };
    alarm 5;
    while (defined $fold->{text}) {
	push @lines, $fold->retrieve =~ s/\e\[[\d;]*[mK]//gr;
	die "too many lines\n" if @lines > 100;
    }
    alarm 0;
    \@lines;
}

sub folds {
    my($name, $text, $opt, $expect) = @_;
    my $got = eval { lines($text, %$opt) };
    alarm 0;
    is_deeply($got, $expect, $name) or diag $@, explain $got;
}

my @all = (linebreak => LINEBREAK_ALL);

# a wide character that does not fit after the prefix
folds("wide character after prefix", "漢字",
      { width => 2, prefix => ' ' }, [ "漢", " 字" ]);
folds("wide character after long prefix", "aあ",
      { width => 2, prefix => ' ' }, [ "a", " あ" ]);

# run-out leaves only the prefix
folds("run-out after prefix", "aaaa ((bbbb",
      { width => 7, prefix => ' ' x 5, @all },
      [ "aaaa ", "     ((", "     bb", "     bb" ]);
folds("run-out after prefix, word boundary", "xxxxxxx yy(((zzz",
      { width => 7, prefix => ' ' x 5, boundary => 'word', @all },
      [ "xxxxxxx ", "     yy", "     ((", "     (z", "     zz" ]);

# colors around the prefix-only line
{
    my $got = eval { lines("word\e[41m(\x{a0}", width => 2, prefix => ' ', @all) };
    alarm 0;
    ok($got, "color after prefix does not hang") or diag $@;
    is(join('', map { s/^ //r } @{$got // []}), "word(\x{a0}", "and keeps the text");
}

# sequences are not taken as visible text before the run-out
folds("erase line before run-out", "\e[K(word",
      { width => 4, boundary => 'word', @all }, [ "(", "word" ]);
folds("erase line before wide run-in", "\e[K「é",
      { width => 1, @all }, [ "「", "é" ]);

# the width of a colored prefix does not count the sequences
folds("colored prefix", "aaaa bbbb cccc dddd",
      { width => 8, prefix => "\e[1m> \e[m", boundary => 'word', @all },
      [ "aaaa ", "> bbbb ", "> cccc ", "> dddd" ]);

# a line that starts with the prefix by itself
folds("indented line same as prefix", "    (aa",
      { width => 5, prefix => ' ' x 4, @all }, [ "    (", "    a", "    a" ]);

# the filler of splitwide is not taken by run-in
{
    my $fold = Text::ANSI::Fold->new(width => 5, splitwide => 1, @all);
    is_deeply([ $fold->fold("あいうえお") ],
	      [ "あい\x{a0}", "\x{a0}えお", 5 ], "splitwide with run-in");
    $fold = Text::ANSI::Fold->new(
	width => 5, splitwide => 1, lefthalf => '<', righthalf => '>', @all);
    is_deeply([ $fold->fold("あいうえお") ],
	      [ "あい<", ">えお", 5 ], "splitwide with visible filler");
}

# sequences with no visible text after them stay at the end of a full line
{
    my $image = "\e]1337;File=x:AAAA\a";
    my $fold = Text::ANSI::Fold->new(width => 5);
    is_deeply([ $fold->fold("     \e[5D$image") ],
	      [ "     \e[5D$image", "", 5 ], "image after spaces of the same width");
    is_deeply([ $fold->fold("     \e[5D$image\n") ],
	      [ "     \e[5D$image\n", "", 5 ], "and before a newline");
    is_deeply([ $fold->fold("abcde\e[3D") ],
	      [ "abcde\e[3D", "", 5 ], "cursor movement at the end");
    is_deeply([ $fold->fold("abcde\e[31m") ],
	      [ "abcde\e[31m\e[m", "", 5 ], "color at the end");
    is_deeply([ $fold->fold("abcde\e[3Dxyz") ],
	      [ "abcde", "\e[3Dxyz", 5 ], "cursor movement before text goes next");
    is_deeply([ $fold->fold("abcde\e[31mxyz\e[m") ],
	      [ "abcde", "\e[31mxyz\e[m", 5 ], "color before text goes next");
    $fold = Text::ANSI::Fold->new(width => 5, trim => 1);
    is_deeply([ $fold->fold("     \e[5D$image") ],
	      [ "     \e[5D$image", "", 5 ], "image line with trim");
}

done_testing;
