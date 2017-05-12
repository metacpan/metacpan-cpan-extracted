use strict;
use warnings;
use utf8;
use Test::More;
use Text::CharWidth qw(mbwidth);

BEGIN {
	use_ok 'Text::UnicodeBox::Table';
};

# If LC_ environment variables can't see this string encoded in the proper format (i.e., called in a server context with no controlling terminal),
# then this module can't operate with Unicode or UTF-8 encoded strings.
my $skip_unicode_tests = mbwidth("象") == 2 ? 0 : 1;

$Text::UnicodeBox::Utility::report_on_failure = 1;

my @columns = qw(id ts log);
my @rows = (
	[ 1, '2012-04-16 12:34:16', 'blakblkj welkjwe' ],
	[ 2, '2012-04-16 16:30:43', 'Eric was here' ],
	[ 3, '2012-04-16 16:31:43', 'Eric was here again' ],
);

my $table = Text::UnicodeBox::Table->new();
isa_ok $table, 'Text::UnicodeBox::Table';

$table->add_header({ style => 'heavy' }, @columns);
$table->add_row(@$_) foreach @rows;

is "\n" . $table->render, <<END_BOX, "Sample MySQL table output";

┏━━━━┳━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━┓
┃ id ┃ ts                  ┃ log                 ┃
┡━━━━╇━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━┩
│  1 │ 2012-04-16 12:34:16 │ blakblkj welkjwe    │
│  2 │ 2012-04-16 16:30:43 │ Eric was here       │
│  3 │ 2012-04-16 16:31:43 │ Eric was here again │
└────┴─────────────────────┴─────────────────────┘
END_BOX

{
	my $alt_table = Text::UnicodeBox::Table->new( style => 'heavy_header' );
	$alt_table->add_header(@columns);
	$alt_table->add_row(@$_) foreach @rows;
	is $alt_table->render, $table->render, "Style: heavy_header";
}

$table = Text::UnicodeBox::Table->new();

$table->add_header({ top => 'double', bottom => 'double' }, @columns);
$table->add_row(@{ $rows[0] });
$table->add_row(@{ $rows[1] });
$table->add_row({ bottom => 'double' }, @{ $rows[2] });

is "\n" . $table->render, <<END_BOX, "Different take on the rendering";

╒════╤═════════════════════╤═════════════════════╕
│ id │ ts                  │ log                 │
╞════╪═════════════════════╪═════════════════════╡
│  1 │ 2012-04-16 12:34:16 │ blakblkj welkjwe    │
│  2 │ 2012-04-16 16:30:43 │ Eric was here       │
│  3 │ 2012-04-16 16:31:43 │ Eric was here again │
╘════╧═════════════════════╧═════════════════════╛
END_BOX

{
	my $alt_table = Text::UnicodeBox::Table->new( style => 'horizontal_double' );
	$alt_table->add_header(@columns);
	$alt_table->add_row(@$_) foreach @rows;
	is $alt_table->render, $table->render, "Style: horizontal_double";
}

$table = Text::UnicodeBox::Table->new();

$table->add_header({ top => 'double', bottom => 'double' }, @columns);
$table->add_row({ bottom => 'light' }, @{ $rows[0] });
$table->add_row({ bottom => 'light' }, @{ $rows[1] });
$table->add_row({ bottom => 'double' }, @{ $rows[2] });

is "\n" . $table->render, <<END_BOX, "Lines in between rows";

╒════╤═════════════════════╤═════════════════════╕
│ id │ ts                  │ log                 │
╞════╪═════════════════════╪═════════════════════╡
│  1 │ 2012-04-16 12:34:16 │ blakblkj welkjwe    │
├────┼─────────────────────┼─────────────────────┤
│  2 │ 2012-04-16 16:30:43 │ Eric was here       │
├────┼─────────────────────┼─────────────────────┤
│  3 │ 2012-04-16 16:31:43 │ Eric was here again │
╘════╧═════════════════════╧═════════════════════╛
END_BOX

if (! $skip_unicode_tests) {
	$table = Text::UnicodeBox::Table->new();

	$table->add_header({ top => 'double', bottom => 'double' }, @columns);
	$table->add_row(1, '2012-04-16 12:34:16', "象形文字象形文字");
	$table->add_row({ bottom => 'double' }, @{ $rows[1] });

	is "\n" . $table->render, <<END_BOX, "Unicode table data";

╒════╤═════════════════════╤══════════════════╕
│ id │ ts                  │ log              │
╞════╪═════════════════════╪══════════════════╡
│  1 │ 2012-04-16 12:34:16 │ 象形文字象形文字 │
│  2 │ 2012-04-16 16:30:43 │ Eric was here    │
╘════╧═════════════════════╧══════════════════╛
END_BOX
}

$table = Text::UnicodeBox::Table->new( style => 'horizontal_double' );

$table->add_header({ alignment => [ 'left', 'right', 'right' ] }, @columns);
$table->add_row(@$_) foreach @rows;

is "\n" . $table->render, <<END_BOX, "Custom alignment";

╒════╤═════════════════════╤═════════════════════╕
│ id │ ts                  │ log                 │
╞════╪═════════════════════╪═════════════════════╡
│ 1  │ 2012-04-16 12:34:16 │    blakblkj welkjwe │
│ 2  │ 2012-04-16 16:30:43 │       Eric was here │
│ 3  │ 2012-04-16 16:31:43 │ Eric was here again │
╘════╧═════════════════════╧═════════════════════╛
END_BOX

$table = Text::UnicodeBox::Table->new( style => 'horizontal_double' );

$table->add_header({
	header_alignment => [ 'left', 'right', 'right' ],
	alignment => [ 'left', 'right', 'right' ],
}, @columns);
$table->add_row(@$_) foreach @rows;

is "\n" . $table->render, <<END_BOX, "Custom alignment";

╒════╤═════════════════════╤═════════════════════╕
│ id │                  ts │                 log │
╞════╪═════════════════════╪═════════════════════╡
│ 1  │ 2012-04-16 12:34:16 │    blakblkj welkjwe │
│ 2  │ 2012-04-16 16:30:43 │       Eric was here │
│ 3  │ 2012-04-16 16:31:43 │ Eric was here again │
╘════╧═════════════════════╧═════════════════════╛
END_BOX

done_testing;
