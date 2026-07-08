#!perl

use 5.016;
use strict;
use warnings;

use Test::More;
use Text::MarkdownAdoc;

#===========================================================================
# Headings, Paragraphs, Thematic Breaks, Front Matter
#===========================================================================

my $conv = Text::MarkdownAdoc->new();

# --- empty document ---
is($conv->convert(''),   '', 'empty document → empty string');
is($conv->convert("\n"), '', 'whitespace-only → empty string');
is($conv->convert("  \n  \n"), '', 'blank lines → empty string');

# --- ATX headings levels 1–6 ---
is($conv->convert('# Title'),        "= Title\n",        'ATX level 1');
is($conv->convert('## Section'),     "== Section\n",     'ATX level 2');
is($conv->convert('### Sub'),        "=== Sub\n",        'ATX level 3');
is($conv->convert('#### Sub2'),      "==== Sub2\n",      'ATX level 4');
is($conv->convert('##### Sub3'),     "===== Sub3\n",     'ATX level 5');
is($conv->convert('###### Sub4'),    "====== Sub4\n",    'ATX level 6');

# --- ATX trailing # stripping ---
is($conv->convert('## Foo ##'),  "== Foo\n",  'ATX trailing # stripped');
is($conv->convert('# Bar ###'),  "= Bar\n",   'ATX trailing ### stripped');

# --- ATX with leading/trailing whitespace ---
is($conv->convert('  ##  Hello world  '), "== Hello world\n", 'ATX with surrounding whitespace');

# --- setext heading level 1 and level 2 ---
is($conv->convert("Title\n====="),   "= Title\n",   'setext level 1 (=)');
is($conv->convert("Section\n------"), "== Section\n", 'setext level 2 (-)');
is($conv->convert("Title\n========"), "= Title\n",  'setext level 1 (= multiple)');
is($conv->convert("Section\n----"),   "== Section\n", 'setext level 2 (- minimal)');

# --- paragraph text preserved ---
is($conv->convert("Hello world"),    "Hello world\n", 'single paragraph');
is($conv->convert("Line one\nLine two"), "Line one\nLine two\n", 'two-line paragraph');

# --- hard line break (trailing two spaces) ---
is($conv->convert("Hello  \nworld"), "Hello +\nworld\n", 'hard break: trailing 2 spaces');

# --- hard line break (trailing backslash) ---
is($conv->convert("Hello\\\nworld"), "Hello +\nworld\n", 'hard break: trailing backslash');

# --- thematic break variants ---
is($conv->convert("---"),     "'''\n", 'thematic break ---');
is($conv->convert("***"),     "'''\n", 'thematic break ***');
is($conv->convert("___"),     "'''\n", 'thematic break ___');
is($conv->convert("------"),  "'''\n", 'thematic break -----');
is($conv->convert("* * *"),   "'''\n", 'thematic break * * *');
is($conv->convert("- - -"),   "'''\n", 'thematic break - - -');

# --- front matter: title only ---
{
    my $input = "---\ntitle: My Doc\n---\n\nBody text.\n";
    my $expected = "= My Doc\n\nBody text.\n";
    is($conv->convert($input), $expected, 'front matter title');
}

# --- front matter: arbitrary attributes ---
{
    my $input = "---\nauthor: Jane Doe\nversion: 1.0\n---\n\nContent.\n";
    my $expected = ":author: Jane Doe\n:version: 1.0\n\nContent.\n";
    is($conv->convert($input), $expected, 'front matter attributes');
}

# --- front matter title + attributes ---
{
    my $input = "---\ntitle: My Doc\nauthor: Jane Doe\n---\n\nBody.\n";
    my $expected = "= My Doc\n:author: Jane Doe\n\nBody.\n";
    is($conv->convert($input), $expected, 'front matter title + attributes');
}

# --- front matter title suppressed when body has level-1 ATX heading ---
{
    my $input = "---\ntitle: Override\n---\n\n# Body Title\n\nText.\n";
    # Body has # Body Title so front matter title is suppressed.
    # # Body Title converts to = Body Title
    my $expected = "= Body Title\n\nText.\n";
    is($conv->convert($input), $expected, 'front matter title suppressed by body ATX h1');
}

# --- front matter title suppressed when body has setext h1 ---
{
    my $input = "---\ntitle: Override\n---\n\nBody Title\n==========\n\nText.\n";
    my $expected = "= Body Title\n\nText.\n";
    is($conv->convert($input), $expected, 'front matter title suppressed by body setext h1');
}

# --- document with heading + paragraph ---
{
    my $input = "# Header\n\nBody paragraph.\n";
    my $expected = "= Header\n\nBody paragraph.\n";
    is($conv->convert($input), $expected, 'heading + paragraph');
}

# --- multiple paragraphs separated by blank lines ---
{
    my $input = "First para.\n\nSecond para.\n";
    my $expected = "First para.\n\nSecond para.\n";
    is($conv->convert($input), $expected, 'multiple paragraphs');
}

# --- trailing newline normalization ---
{
    my $input = "Text.\n\n";
    my $expected = "Text.\n";
    is($conv->convert($input), $expected, 'trailing newline normalization');
}

# --- setext vs thematic break disambiguation ---
# setext: paragraph text followed by --- => heading, not thematic break
{
    my $input = "A heading\n---\n\nParagraph.\n";
    my $expected = "== A heading\n\nParagraph.\n";
    is($conv->convert($input), $expected, 'setext heading not confused with thematic break');
}

# thematic break after a heading: --- is thematic break
{
    my $input = "# H1\n\n---\n\nMore.\n";
    my $expected = "= H1\n\n'''\n\nMore.\n";
    is($conv->convert($input), $expected, 'thematic break after heading');
}

# --- front matter: no title, just attributes ---
{
    my $input = "---\nfoo: bar\n---\n\nText.\n";
    my $expected = ":foo: bar\n\nText.\n";
    is($conv->convert($input), $expected, 'front matter attributes only');
}

done_testing();