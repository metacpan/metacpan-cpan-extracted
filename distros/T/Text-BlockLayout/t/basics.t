use Test::More tests => 5;
use Text::BlockLayout;

my $tb = Text::BlockLayout->new(
    max_width   => 20,
    separator   => '; ',
);

$tb->add_text('This is longer than 20 chars');
$tb->add_text('short');
$tb->add_line('Short.');
$tb->add_line('Another.');

is $tb->formatted, <<EXPECTED, 'Basic formatting';
This is longer than
20 chars; short
Short.
Another.
EXPECTED

# test off-by-one errors:

$tb = Text::BlockLayout->new(
    max_width   => 10,
    separator   => '.',
);

$tb->add_text('012345 789');
is $tb->formatted, "012345 789\n", 'Text with exactly max width is not wrapped';

$tb = Text::BlockLayout->new(
    max_width   => 10,
    separator   => '.',
);

$tb->add_text('012345 7890');
is $tb->formatted, "012345\n7890\n", 'Text with width 1 + max_wdith is wrapped';

$tb = Text::BlockLayout->new(
    max_width   => 37,
    separator   => '; ',
);
$tb->add_line('abc');
$tb->add_text('def');

is $tb->formatted, "abc\ndef\n", 'add_line + add_text';

$tb = Text::BlockLayout->new(
    max_width                   => 5,
    wrap_predefined_lines       => 0,
);
$tb->add_line('bla bla');

is $tb->formatted, "bla bla\n", 'wrap_predefined_lines';

