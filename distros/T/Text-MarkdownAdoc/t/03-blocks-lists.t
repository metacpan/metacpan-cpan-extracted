#!perl

use 5.016;
use strict;
use warnings;

use Test::More;
use Text::MarkdownAdoc;

#===========================================================================
# Fenced Code Blocks, Blockquotes, Lists, Admonitions
#===========================================================================

my $conv = Text::MarkdownAdoc->new();

# --- fenced code block with language ---
{
    my $input = "```perl\nprint 1;\n```\n";
    my $expected = "[source,perl]\n----\nprint 1;\n----\n";
    is($conv->convert($input), $expected, 'fenced code with language');
}

# --- fenced code block without language ---
{
    my $input = "```\nplain code\n```\n";
    my $expected = "----\nplain code\n----\n";
    is($conv->convert($input), $expected, 'fenced code without language');
}

# --- fenced code block with blank lines inside ---
{
    my $input = "```\nline1\n\nline3\n```\n";
    my $expected = "----\nline1\n\nline3\n----\n";
    is($conv->convert($input), $expected, 'fenced code with blank lines');
}

# --- tilde-fenced code block ---
{
    my $input = "~~~ruby\nputs 'hi'\n~~~\n";
    my $expected = "[source,ruby]\n----\nputs 'hi'\n----\n";
    is($conv->convert($input), $expected, 'tilde-fenced code');
}

# --- unclosed fenced code block at end of document ---
{
    my $input = "```sh\necho hello\n";
    my $expected = "[source,sh]\n----\necho hello\n----\n";
    is($conv->convert($input), $expected, 'unclosed fenced code');
}

# --- plantuml diagram block (uses .... delimiter) ---
{
    my $input = "```plantuml\n\@startuml\nAlice -> Bob: Hello\n\@enduml\n```\n";
    my $expected = "[plantuml]\n....\n\@startuml\nAlice -> Bob: Hello\n\@enduml\n....\n";
    is($conv->convert($input), $expected, 'plantuml diagram block');
}

# --- mermaid diagram block ---
{
    my $input = "```mermaid\ngraph TD\nA-->B\n```\n";
    my $expected = "[mermaid]\n....\ngraph TD\nA-->B\n....\n";
    is($conv->convert($input), $expected, 'mermaid diagram block');
}

# --- indented code block (4 spaces) ---
{
    my $input = "    code line 1\n    code line 2\n";
    my $expected = "....\ncode line 1\ncode line 2\n....\n";
    is($conv->convert($input), $expected, 'indented code block (4 spaces)');
}

# --- indented content inside list item is NOT a code block ---
{
    my $input = "- item one\n  continuation\n- item two\n";
    my $expected = "* item one\n  continuation\n* item two\n";
    is($conv->convert($input), $expected, 'list indent not code block');
}

# --- basic blockquote ---
{
    my $input = "> Something someone said.\n";
    my $expected = "____\nSomething someone said.\n____\n";
    is($conv->convert($input), $expected, 'basic blockquote');
}

# --- nested blockquote (2 levels) ---
{
    my $input = "> > Deep quote\n";
    my $expected = "______\nDeep quote\n______\n";
    is($conv->convert($input), $expected, 'nested blockquote');
}

# --- blockquote containing a list ---
{
    my $input = "> - item a\n> - item b\n";
    my $expected = "____\n* item a\n* item b\n____\n";
    is($conv->convert($input), $expected, 'blockquote with list');
}

# --- admonition from blockquote with bold label ---
{
    my $input = "> **Note:** This is important.\n";
    my $expected = "NOTE: This is important.\n";
    is($conv->convert($input), $expected, 'admonition from blockquote bold label');
}

# --- admonition from plain paragraph marker ---
{
    my $input = "Note: This is a note paragraph.\n";
    my $expected = "NOTE: This is a note paragraph.\n";
    is($conv->convert($input), $expected, 'admonition from plain paragraph');
}

# --- multi-paragraph admonition block ---
{
    my $input = "> **Warning:** Be careful.\n>\n> Really careful.\n";
    my $expected = "[WARNING]\n====\nBe careful.\n\nReally careful.\n====\n";
    is($conv->convert($input), $expected, 'multi-paragraph admonition');
}

# --- simple unordered list (tight) ---
{
    my $input = "- item one\n- item two\n- item three\n";
    my $expected = "* item one\n* item two\n* item three\n";
    is($conv->convert($input), $expected, 'tight unordered list');
}

# --- simple unordered list (loose) ---
{
    my $input = "- item one\n\n- item two\n\n- item three\n";
    my $expected = "* item one\n\n* item two\n\n* item three\n";
    is($conv->convert($input), $expected, 'loose unordered list');
}

# --- nested unordered list (2 levels) ---
{
    my $input = "- item one\n  - nested item\n- item two\n";
    my $expected = "* item one\n** nested item\n* item two\n";
    is($conv->convert($input), $expected, 'nested unordered list');
}

# --- simple ordered list ---
{
    my $input = "1. first\n2. second\n3. third\n";
    my $expected = ". first\n. second\n. third\n";
    is($conv->convert($input), $expected, 'ordered list');
}

# --- nested ordered list ---
{
    my $input = "1. first\n   1. nested\n2. second\n";
    my $expected = ". first\n.. nested\n. second\n";
    is($conv->convert($input), $expected, 'nested ordered list');
}

# --- mixed nested list (ul inside ol) ---
{
    my $input = "1. first\n   - nested ul\n2. second\n";
    my $expected = ". first\n** nested ul\n. second\n";
    is($conv->convert($input), $expected, 'ul inside ol');
}

# --- mixed nested list (ol inside ul) ---
{
    my $input = "- item\n  1. nested ol\n- item2\n";
    my $expected = "* item\n.. nested ol\n* item2\n";
    is($conv->convert($input), $expected, 'ol inside ul');
}

# --- task list items (checked and unchecked) ---
{
    my $input = "- [x] done\n- [ ] not done\n- [X] also done\n";
    my $expected = "* [x] done\n* [ ] not done\n* [x] also done\n";
    is($conv->convert($input), $expected, 'task list');
}

# --- list item with continuation: code block after list ---
# After a blank line following a list item, indented content
# is treated as an indented code block (outside list context).
{
    my $input = "- item one\n\n    code\n";
    my $expected = "* item one\n\n....\ncode\n....\n";
    is($conv->convert($input), $expected, 'indented code after list blank line');
}

done_testing();