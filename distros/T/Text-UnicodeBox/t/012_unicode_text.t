use strict;
use warnings;
use utf8;
use Test::More;
use Encode qw(encode decode);
use Text::CharWidth qw(mbwidth);

BEGIN {
	# If LC_ environment variables can't see this string encoded in the proper format (i.e., called in a server context with no controlling terminal),
	# then this module can't operate with Unicode or UTF-8 encoded strings.
	if (mbwidth("象") != 2) {
		plan skip_all => "Can't run without Locale set";
		exit;
	}

	use_ok 'Text::UnicodeBox';
	use_ok 'Text::UnicodeBox::Control', qw(:all);
	use_ok 'Text::UnicodeBox::Text', qw(:all);
};

my $box = Text::UnicodeBox->new(
	whitespace_character => '.',
);
isa_ok $box, 'Text::UnicodeBox';

my $kanji = " 象形文字象形文字 ";
is length($kanji), 10, "Double-width Kanji characters";
is BOX_STRING($kanji)->length, 18, "Width as seen by the module";

$box->add_line(
	'.', BOX_START( style => 'heavy', top => 'heavy', bottom => 'heavy' ),
	$kanji,
	BOX_END(), '.',
);

is $box->render, <<END_BOX, "Box with Kanji unicode text";
.┏━━━━━━━━━━━━━━━━━━┓.
.┃ 象形文字象形文字 ┃.
.┗━━━━━━━━━━━━━━━━━━┛.
END_BOX

# Miscellanous foreign character sets

$box = Text::UnicodeBox->new();
isa_ok $box, 'Text::UnicodeBox';

is BOX_STRING(" suscripción  ")->length, 14, "Spanish";
is BOX_STRING(" qualité      ")->length, 14, "Portuegese";
is BOX_STRING(" фотографий   ")->length, 14, "Russian";
is BOX_STRING(" 收集库内增加 ")->length, 14, "Chinese";
is BOX_STRING(" 写真の販売エ ")->length, 14, "Japanese";

$box->add_line( BOX_START( style => 'heavy', top => 'heavy' ), " suscripción  ", BOX_END() );
$box->add_line( BOX_START( style => 'heavy' ),                 " qualité      ", BOX_END() );
$box->add_line( BOX_START( style => 'heavy' ),                 " фотографий   ", BOX_END() );
$box->add_line( BOX_START( style => 'heavy' ),                 " 收集库内增加 ", BOX_END() );
$box->add_line( BOX_START(style => 'heavy',bottom => 'heavy'), " 写真の販売エ ", BOX_END() );

is $box->render,
"┏━━━━━━━━━━━━━━┓
┃ suscripción  ┃
┃ qualité      ┃
┃ фотографий   ┃
┃ 收集库内增加 ┃
┃ 写真の販売エ ┃
┗━━━━━━━━━━━━━━┛
", "Box with many languages";

done_testing;
