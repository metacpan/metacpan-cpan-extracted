use strict;
use warnings;
use utf8;
use Test::More;
use Term::ANSIColor;

BEGIN {
	use_ok 'Text::UnicodeBox';
	use_ok 'Text::UnicodeBox::Control', qw(:all);
	use_ok 'Text::UnicodeBox::Text', qw(:all);
};

my $colored_text = ' '.colored("Bright!", 'yellow on_magenta').' ';
my $obj = BOX_STRING($colored_text);
is $obj->length, 9, "Colored text has correct length";

my $box = Text::UnicodeBox->new(
	whitespace_character => '.',
);
isa_ok $box, 'Text::UnicodeBox';

$box->add_line(
	'.', BOX_START( style => 'heavy', top => 'heavy', bottom => 'heavy' ),
	$colored_text,
	BOX_END(), '.',
);

is $box->render,
	".┏━━━━━━━━━┓.\n".
	".┃".$colored_text."┃.\n".
	".┗━━━━━━━━━┛.\n",
	"Colored text in a box";

done_testing;
