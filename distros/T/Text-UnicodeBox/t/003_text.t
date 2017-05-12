use strict;
use warnings;
use Test::More;
use Term::ANSIColor qw(:constants colored);
use Data::Dumper;
use utf8;
use Text::CharWidth qw(mbwidth);

BEGIN {
	use_ok 'Text::UnicodeBox::Text', qw(:all);
};

# If LC_ environment variables can't see this string encoded in the proper format (i.e., called in a server context with no controlling terminal),
# then this module can't operate with Unicode or UTF-8 encoded strings.
my $skip_unicode_tests = mbwidth("象") == 2 ? 0 : 1;

my $part = BOX_STRING("Hello world");
isa_ok $part, 'Text::UnicodeBox::Text';
is $part->value, 'Hello world';
is $part->length, length('Hello world');

## align_and_pad

$part->align_and_pad(14);
is $part->value, ' ' . 'Hello world   ' . ' ', "align_and_pad() changes value in place with spaces before and after";

$part = BOX_STRING(45);
$part->align_and_pad(3);
is $part->value, ' '.' 45'.' ', "Numbers are aligned right";

$part = BOX_STRING(72.5);
$part->align_and_pad(5);
is $part->value, ' '.' 72.5'.' ', "Fractional numbers are still numbers";

## Lines

$part = BOX_STRING(
	"This is line one\n".
	"This is line two"
);
my @lines = $part->lines();
is int @lines, 2, "Part split into two lines";
is $part->longest_line_length, 16, "Longest line length";

## Split

$part = BOX_STRING("This is a very long string that needs to be split into multiple parts");

my @segments = $part->split(
	max_width => 20,
	break_words => 1,
);

is_deeply [ map { $_->value } @segments ], [
	'This is a very long ',
	'string that needs to',
	' be split into multi',
	'ple parts',
], "Split max_width => 20, break_words => 1";

## Split with color

$part = BOX_STRING(colored("This is a very long string that needs to be split into multiple parts", 'blue'));

@segments = $part->split(
	max_width => 20,
	break_words => 1,
);

is_deeply [ map { $_->value } @segments ], [
	BLUE . 'This is a very long ' . RESET,
	BLUE . 'string that needs to' . RESET,
	BLUE . ' be split into multi' . RESET,
	BLUE . 'ple parts' . RESET,
], "Split max_width => 20, break_words => 1, all one color";

## More complex styling

$part = BOX_STRING(
	colored("This is a very long ", 'blue') .
	colored("string", 'bold') .
	colored(" that needs to be split into ", 'blue') .
	colored("multiple parts", 'on_blue')
);

@segments = $part->split(
	max_width => 20,
	break_words => 1,
);

is_deeply [ map { $_->value } @segments ], [
	BLUE . 'This is a very long ' . RESET,
	BOLD . 'string' . RESET . BLUE . ' that needs to' . RESET,
	BLUE . ' be split into ' . RESET . ON_BLUE . 'multi' . RESET,
	ON_BLUE . 'ple parts' . RESET,
], "Split max_width => 20, break_words => 1, various colors and styles";

## Split without breaking words

$part = BOX_STRING("This is a very long string that needs to be split into multiple parts");

@segments = $part->split(
	max_width => 20,
);

is_deeply [ map { $_->value } @segments ], [
	'This is a very long ',
	'string that needs to',
	' be split into ',
	'multiple parts',
], "Split max_width => 20, break_words => 0";

## Split without breaking words with color

$part = BOX_STRING(colored("This is a very long string that needs to be split into multiple parts", "blue"));

@segments = $part->split(
	max_width => 20,
);

is_deeply [ map { $_->value } @segments ], [
	BLUE . 'This is a very long ' . RESET,
	BLUE . 'string that needs to' . RESET,
	BLUE . ' be split into ' . RESET,
	BLUE . 'multiple parts' . RESET,
], "Split max_width => 20, break_words => 0, all one color";

## Split unicode text

if (! $skip_unicode_tests) {
	# "I Can Eat Glass" from http://www.columbia.edu/~fdc/utf8/
	my $text = <<ENDTEXT;
Μπορώ να φάω σπασμένα γυαλιά χωρίς να πάθω τίποτα.
私はガラスを食べられます。それは私を傷つけません。
我能吞下玻璃而不伤身体。
ᛁᚳ᛫ᛗᚨᚷ᛫ᚷᛚᚨᛋ᛫ᛖᚩᛏᚪᚾ᛫ᚩᚾᛞ᛫ᚻᛁᛏ᛫ᚾᛖ᛫ᚻᛖᚪᚱᛗᛁᚪᚧ᛫ᛗᛖ᛬
Я могу есть стекло, оно мне не вредит.
나는 유리를 먹을 수 있어요. 그래도 아프지 않아요
ENDTEXT

	$part = BOX_STRING($text);

	@lines = $part->lines();
	is int @lines, 6, "Got six lines from 'I Can Eat Glass'";

	my @got;
	foreach my $line (@lines) {
		my @segment_values;
		foreach my $segment ($line->split( max_width => 20, break_words => 1 )) {
			push @segment_values, $segment->value;
		}
		push @got, \@segment_values;
	}

	is_deeply
		\@got,
		[
			[
				"Μπορώ να φάω σπασμέν",
				"α γυαλιά χωρίς να πά",
				"θω τίποτα.",
			],
			[
				"私はガラスを食べられ",
				"ます。それは私を傷つ",
				"けません。",
			],
			[
				"我能吞下玻璃而不伤身",
				"体。",
			],
			[
				"ᛁᚳ᛫ᛗᚨᚷ᛫ᚷᛚᚨᛋ᛫ᛖᚩᛏᚪᚾ᛫ᚩᚾ",
				"ᛞ᛫ᚻᛁᛏ᛫ᚾᛖ᛫ᚻᛖᚪᚱᛗᛁᚪᚧ᛫ᛗᛖ",
				"᛬",
			],
			[
				"Я могу есть стекло, ",
				"оно мне не вредит.",
			],
			[
				"나는 유리를 먹을 수 ",
				"있어요. 그래도 아프",
				"지 않아요",
			],
		],
		"Split six lines of 'I Can Eat Glass' at 20 width";
}

done_testing;

sub print_segments {
	my @segments = @_;
	foreach my $segment (@segments) {
		foreach my $char (split //, $segment->value) {
			if (ord($char) == 27) {
				print '^';
			}
			else {
				print $char;
			}
		}
		print "\n";
	}
}

