
use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
	use_ok 'Text::UnicodeBox';
	use_ok 'Text::UnicodeBox::Control', qw(:all);
};

$Text::UnicodeBox::Utility::report_on_failure = 1;

my $box = Text::UnicodeBox->new();

$box->add_line(
	BOX_START( style => 'double', top => 'double', bottom => 'double' ), '   ', BOX_END(),
	'    ',
	BOX_START( style => 'heavy', top => 'heavy', bottom => 'heavy' ), '   ', BOX_END()
);

$box->add_line(
	'     ',
	BOX_START( style => 'heavy', top => 'heavy', bottom => 'heavy' ), '   ', BOX_END(),
	'   ',
	BOX_START( style => 'light', top => 'light', bottom => 'light' ), '   ', BOX_END(),
);

$box->add_line(
	'  ', BOX_START( style => 'light', top => 'heavy' ), '    ', BOX_END()
);
$box->add_line(
	'  ', BOX_START( style => 'light', bottom => 'heavy' ), '    ', BOX_END()
);

is "\n" . $box->render, <<END_BOX, "Multiple boxes per line with many different styles";

╔═══╗    ┏━━━┓
║   ║    ┃   ┃
╚═══╝┏━━━╋━━━╃───┐
     ┃   ┃   │   │
  ┍━━┻━┯━┛   └───┘
  │    │
  │    │
  ┕━━━━┙
END_BOX

done_testing;
