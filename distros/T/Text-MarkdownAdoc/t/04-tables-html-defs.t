#!perl

use 5.016;
use strict;
use warnings;

use Test::More;
use Text::MarkdownAdoc;

#===========================================================================
# GFM Tables, HTML Blocks, Definition Lists, Heading IDs
#===========================================================================

my $conv = Text::MarkdownAdoc->new();

# --- basic GFM table with header (compact format) ---
{
    my $input = "| A | B |\n|---|---|\n| 1 | 2 |\n";
    my $expected = "|===\n| A | B\n\n| 1 | 2\n|===\n";
    is($conv->convert($input), $expected, 'basic table with header');
}

# --- table with left/center/right alignment ---
{
    my $input = "| A | B | C |\n|:---|:---:|---:|\n| x | y | z |\n";
    my $expected = "[cols=\"<,^,>\"]\n|===\n| A | B | C\n\n| x | y | z\n|===\n";
    is($conv->convert($input), $expected, 'table with alignment');
}

# --- table with all-default alignment (no [cols=...]) ---
{
    my $input = "| X | Y | Z |\n|---|---|---|\n| 1 | 2 | 3 |\n";
    my $expected = "|===\n| X | Y | Z\n\n| 1 | 2 | 3\n|===\n";
    is($conv->convert($input), $expected, 'table all-default alignment');
}

# --- table with pipe in cell content (escaped) ---
{
    my $input = "| A | B |\n|---|---|\n| x \\| y | z |\n";
    my $expected = "|===\n| A | B\n\n| x \\| y | z\n|===\n";
    is($conv->convert($input), $expected, 'table pipe in cell');
}

# --- single-column table ---
{
    my $input = "| Single |\n|--------|\n| value  |\n";
    my $expected = "|===\n| Single\n\n| value\n|===\n";
    is($conv->convert($input), $expected, 'single-column table');
}

# --- HTML comment block (single line) ---
{
    my $input = "<!-- single line comment -->\n";
    my $expected = "// single line comment\n";
    is($conv->convert($input), $expected, 'single-line HTML comment');
}

# --- multi-line HTML comment ---
{
    my $input = "<!--\nmulti-line\ncomment\n-->\n";
    my $expected = "////\nmulti-line\ncomment\n////\n";
    is($conv->convert($input), $expected, 'multi-line HTML comment');
}

# --- HTML comment with ! prefix (directive) ---
{
    my $input = "<!-- ! some directive -->\n";
    my $expected = "// some directive\n";
    is($conv->convert($input), $expected, 'HTML comment directive');
}

# --- div block as passthrough ---
{
    my $input = "<div class=\"note\">\nSome content here.\n</div>\n";
    my $expected = "++++\n<div class=\"note\">\nSome content here.\n</div>\n++++\n";
    is($conv->convert($input), $expected, 'div block passthrough');
}

# --- script block as passthrough ---
{
    my $input = "<script>\nconsole.log('hi');\n</script>\n";
    my $expected = "++++\n<script>\nconsole.log('hi');\n</script>\n++++\n";
    is($conv->convert($input), $expected, 'script block passthrough');
}

# --- definition list standard form (kramdown : ) ---
{
    my $input = "Term\n: Definition text here.\n";
    my $expected = "Term::\nDefinition text here.\n";
    is($conv->convert($input), $expected, 'definition list standard form');
}

# --- definition list multiple definitions per term ---
{
    my $input = "Term\n: First definition.\n: Second definition.\n";
    my $expected = "Term::\nFirst definition.\n+\nSecond definition.\n";
    is($conv->convert($input), $expected, 'definition list multiple defs');
}

# --- definition list bold term with :: colons form ---
{
    my $input = "**Term**:: Definition at level 1.\n";
    my $expected = "Term::\nDefinition at level 1.\n";
    is($conv->convert($input), $expected, 'def list bold term :: form');
}

# --- multi-level definition list ---
{
    my $input = "**Term**:: Definition at level 1.\n**Term**::: Definition at level 2.\n";
    my $expected = "Term::\nDefinition at level 1.\n\nTerm:::\nDefinition at level 2.\n";
    is($conv->convert($input), $expected, 'multi-level definition list');
}

# --- heading ID auto-generation (auto_ids option) ---
{
    my $conv2 = Text::MarkdownAdoc->new(auto_ids => 1);
    my $input = "## My Section Title\n";
    my $expected = "[[_my_section_title]]\n== My Section Title\n";
    is($conv2->convert($input), $expected, 'heading ID auto-generation');
}

# --- explicit <a name="..."> anchor in heading ---
{
    my $input = "## <a name=\"my-id\"></a>My Section\n";
    my $expected = "[[my-id]]\n== My Section\n";
    is($conv->convert($input), $expected, 'explicit anchor in heading');
}

# --- explicit <a id="..."> anchor in heading ---
{
    my $input = "## <a id=\"ref-id\"></a>The Section\n";
    my $expected = "[[ref-id]]\n== The Section\n";
    is($conv->convert($input), $expected, 'explicit id anchor in heading');
}

# --- internal cross-reference [text](#id) ---
{
    my $conv2 = Text::MarkdownAdoc->new(auto_ids => 1);
    my $input = "See [the heading](#my-heading).\n\n## My Heading\n";
    my $expected = "See <<_my_heading,the heading>>.\n\n[[_my_heading]]\n== My Heading\n";
    is($conv2->convert($input), $expected, 'internal cross-reference');
}

# --- forward cross-reference resolution (target defined after link) ---
# Text "Target Section" matches heading title, so bare <<>> (no explicit text)
{
    my $conv2 = Text::MarkdownAdoc->new(auto_ids => 1);
    my $input = "See [Target Section](#target-section).\n\n## Target Section\n";
    my $expected = "See <<_target_section>>.\n\n[[_target_section]]\n== Target Section\n";
    is($conv2->convert($input), $expected, 'forward cross-reference');
}

# --- cross-reference where text matches heading title (no explicit text) ---
{
    my $conv2 = Text::MarkdownAdoc->new(auto_ids => 1);
    my $input = "## My Section\n\nSee [My Section](#my-section).\n";
    my $expected = "[[_my_section]]\n== My Section\n\nSee <<_my_section>>.\n";
    is($conv2->convert($input), $expected, 'xref text matches heading title');
}

done_testing();