#!perl

use 5.016;
use strict;
use warnings;

use Test::More;
use Text::MarkdownAdoc;

#===========================================================================
# Inline Formatting, Links, Images, Smart Quotes
#===========================================================================

my $conv = Text::MarkdownAdoc->new();

# --- bold with ** ---
is($conv->convert("**bold**"), "*bold*\n", 'bold with **');
is($conv->convert("a**bold**b"), "a*bold*b\n", 'bold mid-word with **');

# --- bold with __ ---
is($conv->convert("__bold__"), "*bold*\n", 'bold with __');
is($conv->convert("a__bold__b"), "a*bold*b\n", 'bold mid-word with __');

# --- italic with * ---
is($conv->convert("*italic*"), "_italic_\n", 'italic with *');
is($conv->convert("a *italic* b"), "a _italic_ b\n", 'italic with * bounded');

# --- italic with _ ---
is($conv->convert("_italic_"), "_italic_\n", 'italic with _');
is($conv->convert("a _italic_ b"), "a _italic_ b\n", 'italic with _ bounded');

# --- code span basic ---
is($conv->convert("`code`"), "`code`\n", 'code span basic');

# --- code span with backtick inside (double-backtick form) ---
is($conv->convert("``code with ` inside``"), "`code with \` inside`\n", 'code span with backtick inside');

# --- strikethrough ~~ ---
is($conv->convert("~~strike~~"), "[.line-through]#strike#\n", 'strikethrough');

# --- backslash escape ---
is($conv->convert("\\*not italic\\*"), "*not italic*\n", 'backslash escape *');
is($conv->convert("\\_not italic\\_"), "_not italic_\n", 'backslash escape _');
is($conv->convert("\\`not code\\`"), "`not code`\n", 'backslash escape backtick');

# --- inline link [text](url) ---
is($conv->convert("[example](https://example.com)"), "https://example.com[example]\n", 'inline link');

# --- inline link to anchor [text](#id) ---
is($conv->convert("[section](#intro)"), "<<intro,section>>\n", 'inline link to anchor');

# --- inline link to .md file → .adoc xref ---
is($conv->convert("[doc](guide.md)"), "xref:guide.adoc[doc]\n", 'inline link to .md file');

# --- bare URL autolink <https://...> ---
is($conv->convert("<https://example.com>"), "https://example.com\n", 'bare URL autolink');

# --- reference-style link resolution (deferred) ---
{
    my $input = "[link][ref]\n\n[ref]: https://example.com\n";
    my $expected = "https://example.com[link]\n";
    is($conv->convert($input), $expected, 'reference-style link resolved');
}

# --- reference-style shorthand [ref] ---
{
    my $input = "[ref]\n\n[ref]: https://example.com\n";
    my $expected = "https://example.com[ref]\n";
    is($conv->convert($input), $expected, 'reference-style shorthand link');
}

# --- reference-style with empty label [text][] ---
{
    my $input = "[text][]\n\n[text]: https://example.com\n";
    my $expected = "https://example.com[text]\n";
    is($conv->convert($input), $expected, 'reference-style empty label');
}

# --- unresolved reference-style link (literal fallback) ---
{
    my $input = "[missing][nope]\n";
    my $expected = "missing\n";
    is($conv->convert($input), $expected, 'unresolved reference link fallback');
}

# --- inline image ![alt](src) ---
is($conv->convert("text ![logo](img/logo.png) text"), "text image:img/logo.png[logo] text\n", 'inline image');

# --- block image (sole paragraph content) ---
is($conv->convert("![logo](img/logo.png)"), "image::img/logo.png[logo]\n", 'block image');

# --- & entity handling ---
is($conv->convert("A & B"), "A & B\n", '& entity passthrough');

# --- < entity handling ---
is($conv->convert("x < y"), "x < y\n", '< entity passthrough');

# --- &nbsp; entity handling ---
is($conv->convert("word&nbsp;word"), "word{nbsp}word\n", '&nbsp; → {nbsp}');

# --- <br> inline HTML → hard line break ---
is($conv->convert("line<br>break"), "line +break\n", '<br> → hard line break');
is($conv->convert("line<br/>break"), "line +break\n", '<br/> → hard line break');

# --- <del>text</del> → [.line-through]#text# ---
is($conv->convert("<del>deleted</del>"), "[.line-through]#deleted#\n", '<del> → strikethrough');

# --- <strong>text</strong> → *text* ---
is($conv->convert("<strong>bold</strong>"), "*bold*\n", '<strong> → bold');

# --- <em>text</em> → _text_ ---
is($conv->convert("<em>italic</em>"), "_italic_\n", '<em> → italic');

# --- <code>text</code> → `text` ---
is($conv->convert("<code>var</code>"), "`var`\n", '<code> → code span');

# --- <mark>text</mark> → #text# ---
is($conv->convert("<mark>highlight</mark>"), "#highlight#\n", '<mark> → highlight');

# --- <sup>text</sup> → ^text^ ---
is($conv->convert("x<sup>2</sup>"), "x^2^\n", '<sup> → superscript');

# --- <sub>text</sub> → ~text~ ---
is($conv->convert("H<sub>2</sub>O"), "H~2~O\n", '<sub> → subscript');

# --- Unicode smart double quote conversion ---
{
    my $input = "\x{201C}hello\x{201D}";
    my $expected = "\"\`hello\`\"\n";
    is($conv->convert($input), $expected, 'smart double quotes');
}

# --- Unicode smart single quote conversion ---
{
    my $input = "\x{2018}hello\x{2019}";
    my $expected = "'\`hello\`'\n";
    is($conv->convert($input), $expected, 'smart single quotes');
}

# --- nested formatting ---
# ***bold italic*** → **bold italic** (bold wraps, inner * not italic due to word boundaries)
is($conv->convert("***bold italic***"), "**bold italic**\n", 'nested bold+italic ***');

# --- URL-only link where text equals URL ---
is($conv->convert("[https://x.com](https://x.com)"), "https://x.com\n", 'URL-only link → bare URL');

done_testing();