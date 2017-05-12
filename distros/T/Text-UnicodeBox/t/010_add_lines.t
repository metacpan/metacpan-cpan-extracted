use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
	use_ok 'Text::UnicodeBox';
	use_ok 'Text::UnicodeBox::Control', qw(:all);
};

my $box = Text::UnicodeBox->new(
	whitespace_character => '.',
);
isa_ok $box, 'Text::UnicodeBox';

$box->add_line(
	'.', BOX_START( style => 'heavy', top => 'heavy', bottom => 'heavy' ), ' This is a header ', BOX_END(), '.',
);

is $box->buffer, <<END_BOX, "Buffer has an interim state";
.┏━━━━━━━━━━━━━━━━━━┓.
.┃ This is a header ┃.
END_BOX

is $box->render, <<END_BOX, "Render completes the box";
.┏━━━━━━━━━━━━━━━━━━┓.
.┃ This is a header ┃.
.┗━━━━━━━━━━━━━━━━━━┛.
END_BOX

done_testing;
