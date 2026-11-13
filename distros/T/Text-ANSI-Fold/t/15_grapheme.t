use v5.14;
use warnings;
use utf8;
use open IO => ':utf8', ':std';
use Test::More;
use Text::ANSI::Fold;
use Text::VisualWidth::PP qw(vwidth);

sub lines {
    my($text, $width) = @_;
    Text::ANSI::Fold->new(width => $width)->text($text)->chops;
}

# A line is never wider than the width, unless it is one grapheme.
my $emoji = "\N{U+1F468}\N{U+200D}\N{U+1F469}\N{U+200D}\N{U+1F467}"	# family
	  . "\N{U+1F44D}\N{U+1F3FD}\N{U+1F3FD}"				# thumbs up, two modifiers
	  . "\N{U+1FAAA}";						# identification card
for my $width (2 .. 12) {
    my @over = grep { vwidth($_) > $width and (() = /\X/g) > 1 } lines($emoji x 3, $width);
    is(scalar @over, 0, "emoji sequences within width $width");
}

# A long grapheme is not split between lines, even in a long paragraph
# where fold takes the text a part at a time.  Each line is made of
# whole units, when the unit is one grapheme for the perl in use: the
# family emoji is not, before the grapheme rules of Unicode 9.0.
for my $case (
    [ "\N{U+1F468}\N{U+200D}\N{U+1F469}\N{U+200D}\N{U+1F467}\N{U+200D}\N{U+1F466}" => 'family emoji' ],
    [ "x" . "\N{U+301}" x 30 => 'letter with 30 marks' ],
) {
    my($unit, $name) = @$case;
    SKIP: {
	skip "\\b{gcb} is from perl 5.22", 1 if $] < 5.022;
	skip "$name is not one grapheme in this perl", 1 if $unit !~ /\A\X\z/;
	my @split = grep {
	    my $width = $_;
	    grep { !/\A(?:\Q$unit\E)+\z/ } lines($unit x 60, $width);
	} 2 .. 120;
	is("@split", "", "$name is not split");
    }
}

# A combining mark right after the width stays with its letter.
is_deeply([ lines("abe\N{U+301}xyz", 3) ], [ "abe\N{U+301}", "xyz" ],
	  "combining mark after ASCII at the width");

# Japanese is folded at the width.
is_deeply([ lines("日本語の文章です。" x 2, 10) ],
	  [ "日本語の文", "章です。日", "本語の文章", "です。" ],
	  "Japanese at width 10");

done_testing;
