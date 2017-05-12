use strict;
use warnings;
use utf8;
use Test::More;
use Term::ANSIColor qw(:constants colored);

BEGIN {
	use_ok 'Text::UnicodeBox::Table';
};

$Text::UnicodeBox::Utility::report_on_failure = 1;

my @columns = qw(name quote);
my @rows = (
	[
		"Edward R. Murrow\n".
		"  Journalist",
		"To be persuasive we must be believable;\n".
		"to be believable we must be creditable;\n".
		"to be credible we must be truthful.",
	],
	[
		"Mahatma Gandhi",
		"The greatness of a nation and its moral progress can be judged by the way its animals are treated.",
	],
);

## split_lines = 1

my $table = Text::UnicodeBox::Table->new( split_lines => 1 );
$table->add_header({ style => 'heavy' }, @columns);
$table->add_row(@$_) foreach @rows;

is "\n" . $table->render, <<END_BOX, "Split lines";

┏━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ name             ┃ quote                                                                                              ┃
┡━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┩
│ Edward R. Murrow │ To be persuasive we must be believable;                                                            │
│   Journalist     │ to be believable we must be creditable;                                                            │
│                  │ to be credible we must be truthful.                                                                │
│ Mahatma Gandhi   │ The greatness of a nation and its moral progress can be judged by the way its animals are treated. │
└──────────────────┴────────────────────────────────────────────────────────────────────────────────────────────────────┘
END_BOX

## 

$table = Text::UnicodeBox::Table->new( split_lines => 1, column_widths => [ undef, 52 ] );
$table->add_header({ style => 'heavy' }, @columns);
$table->add_row(@$_) foreach @rows;

is "\n" . $table->render, <<END_BOX, "Split lines, wrap cells";

┏━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ name             ┃ quote                                                ┃
┡━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┩
│ Edward R. Murrow │ To be persuasive we must be believable;              │
│   Journalist     │ to be believable we must be creditable;              │
│                  │ to be credible we must be truthful.                  │
│ Mahatma Gandhi   │ The greatness of a nation and its moral progress can │
│                  │  be judged by the way its animals are treated.       │
└──────────────────┴──────────────────────────────────────────────────────┘
END_BOX

## Max width with no need to actually wrap any lines

$table = Text::UnicodeBox::Table->new( split_lines => 1, max_width => 75 );
$table->add_header({ style => 'heavy' }, @columns);
$table->add_row(@{ $rows[0] });

# Test internal fitting logic

$table->_determine_column_widths;
is_deeply $table->column_widths, [ 16, 39 ], "Column widths default to max_column_width; no wrapping done";

is "\n" . $table->render, <<END_BOX, "Split lines, max_width but no wrapping needed";

┏━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ name             ┃ quote                                   ┃
┡━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┩
│ Edward R. Murrow │ To be persuasive we must be believable; │
│   Journalist     │ to be believable we must be creditable; │
│                  │ to be credible we must be truthful.     │
└──────────────────┴─────────────────────────────────────────┘
END_BOX

## Max width with wrapping needed

$table = Text::UnicodeBox::Table->new( split_lines => 1,  max_width => 75 );
$table->add_header({ style => 'heavy' }, @columns);
$table->add_row(@$_) foreach @rows;

$table->_determine_column_widths;
is_deeply $table->column_widths, [ 16, 52 ], "Column widths deduced from max_width";

is "\n" . $table->render, <<END_BOX, "Split lines, wrap cells";

┏━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ name             ┃ quote                                                ┃
┡━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┩
│ Edward R. Murrow │ To be persuasive we must be believable;              │
│   Journalist     │ to be believable we must be creditable;              │
│                  │ to be credible we must be truthful.                  │
│ Mahatma Gandhi   │ The greatness of a nation and its moral progress can │
│                  │  be judged by the way its animals are treated.       │
└──────────────────┴──────────────────────────────────────────────────────┘
END_BOX

## Spaces matter

$table = Text::UnicodeBox::Table->new( split_lines => 1, max_width => 76 );
$table->add_header({ style => 'heavy' }, @columns);
$table->add_row(@$_) foreach @rows;

$table->_determine_column_widths;
is_deeply $table->column_widths, [ 16, 53 ], "Column widths deduced from max_width";

is "\n" . $table->render, <<END_BOX, "Split lines, wrap cells";

┏━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ name             ┃ quote                                                 ┃
┡━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┩
│ Edward R. Murrow │ To be persuasive we must be believable;               │
│   Journalist     │ to be believable we must be creditable;               │
│                  │ to be credible we must be truthful.                   │
│ Mahatma Gandhi   │ The greatness of a nation and its moral progress can  │
│                  │ be judged by the way its animals are treated.         │
└──────────────────┴───────────────────────────────────────────────────────┘
END_BOX

## Splitting and wrapping in the same row

$table = Text::UnicodeBox::Table->new( split_lines => 1, max_width => 76 );
$table->add_header({ style => 'heavy' }, @columns);
$table->add_row($rows[0][0], $rows[1][1]);

is "\n" . $table->render, <<END_BOX, "Splitting and wrapping in same row";

┏━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ name             ┃ quote                                                 ┃
┡━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┩
│ Edward R. Murrow │ The greatness of a nation and its moral progress can  │
│   Journalist     │ be judged by the way its animals are treated.         │
└──────────────────┴───────────────────────────────────────────────────────┘
END_BOX

## Color matters

$table = Text::UnicodeBox::Table->new( split_lines => 1, max_width => 76 );
$table->add_header({ style => 'heavy' }, @columns);
$table->add_row($rows[0][0], colored($rows[1][1], 'blue'));

my $color_start = BLUE;
my $color_end   = RESET;

is "\n" . $table->render, <<END_BOX, "Wrap cells with color";

┏━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ name             ┃ quote                                                 ┃
┡━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┩
│ Edward R. Murrow │ ${color_start}The greatness of a nation and its moral progress can ${color_end} │
│   Journalist     │ ${color_start}be judged by the way its animals are treated.${color_end}         │
└──────────────────┴───────────────────────────────────────────────────────┘
END_BOX

## Wrap words within word boundaries

$table = Text::UnicodeBox::Table->new( split_lines => 1, column_widths => [ 4, 11 ], break_words => 1 );
$table->add_header({ style => 'heavy' }, @columns);
$table->add_row('Mahatma Gandhi', 'The greatness of a nation and its progress');

is "\n" . $table->render, <<END_BOX, "Wrap cells, ignoring word boundaries";

┏━━━━━━┳━━━━━━━━━━━━━┓
┃ name ┃ quote       ┃
┡━━━━━━╇━━━━━━━━━━━━━┩
│ Maha │ The greatne │
│ tma  │ ss of a nat │
│ Gand │ ion and its │
│ hi   │  progress   │
└──────┴─────────────┘
END_BOX

done_testing;
