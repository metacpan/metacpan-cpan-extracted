use strict;
use warnings;

use Test::More;

use Text::AsciidocDown;

sub conv
{
   my ($input, $opts) = @_;
   my $converter = Text::AsciidocDown->new();
   return $converter->convert($input, $opts || {});
}

is(conv('*bold* _emphasis_ and `mono`'), '*bold* _emphasis_ and `mono`', 'strong, emphasis, monospace basic forms');

is(
   conv('alpha*no*beta and alpha_no_beta and alpha#no#beta'),
   'alpha*no*beta and alpha_no_beta and alpha#no#beta',
   'format markers do not apply inside words'
   );

is(conv('#mark# and [.line-through]#gone#'), '<mark>mark</mark> and ~~gone~~', 'mark and line-through conversion');

is(conv(":markdown-strikethrough: <del> </del>\n\n[.line-through]#gone#\n"),
   '<del>gone</del>', 'strikethrough uses configurable mark pair');

# Paired curly quotes default to real curly Unicode characters (not
# downdoc's shared "<q></q>" HTML) so that a round trip through
# Text::MarkdownAdoc is stable, and so that the single-quoted and
# double-quoted forms remain distinguishable in the output. This is a
# documented, verified deviation from downdoc's own default (downdoc uses
# one "quotes" attribute for both forms, defaulting to "<q> </q>"); see
# docs/COMPATIBILITY_REPORT.md.
is(conv("say \"`quoted`\" then '`single`'"),
   "say \x{201C}quoted\x{201D} then \x{2018}single\x{2019}",
   'double- and single-quoted forms use distinct default curly characters');

is(conv(":quotes: &ldquo; &rdquo;\n\n\"`hello`\"\n"), '&ldquo;hello&rdquo;', 'double quote replacement can be configured via quotes');

is(conv(":quotes-single: &lsquo; &rsquo;\n\n'`hello`'\n"),
   '&lsquo;hello&rsquo;', 'single quote replacement can be configured via quotes-single, independent of quotes');

is(conv(":quotes: <q> </q>\n:quotes-single: <q> </q>\n\nsay \"`quoted`\" then '`single`' now\n"),
   'say <q>quoted</q> then <q>single</q> now',
   'both forms can still be configured to the old shared downdoc-parity <q></q> behavior');

# A quoted span's content must be bounded by non-whitespace on both sides,
# mirroring downdoc's QuotedSpanRx (`\S|\S.*?\S`). Whitespace-padded or
# empty spans are not paired-quote matches; they fall through to the
# standalone-marker mechanism instead, which still resolves the individual
# open/close markers correctly.
is(conv('say "` text `" now'),
   "say \x{201C} text \x{201D} now",
   'whitespace-padded double-quote span is not treated as a paired quote, but markers still resolve');

is(conv('empty "``" pair'), "empty \x{201C}\x{201D} pair", 'empty double-quote span is not treated as a paired quote, but markers still resolve');

is(conv('Visit https://example.org/docs[Docs] now.'), 'Visit [Docs](https://example.org/docs) now.', 'URL macro conversion');

is(conv('See link:README.md[Readme].'), 'See [Readme](README.md).', 'link macro conversion');

is(
   conv('Escape \\https://example.org[Docs] and \\link:README.md[Readme].'),
   'Escape <span>https://</span>example.org[Docs] and link:README.md[Readme].',
   'escaped URL and link macros are preserved/obscured'
   );

is(conv(":hide-uri-scheme:\n\nhttps://example.org\n"),
   '[example.org](https://example.org)',
   'hide-uri-scheme uses URL without scheme as visible text');

is(conv('image:assets/logo.svg[Logo]'), '![Logo](assets/logo.svg)', 'inline image conversion');

is(conv('image:assets/logo.svg[]'), '![logo](assets/logo.svg)', 'inline image alt fallback from basename');

is(conv(":imagesdir: img\n\nimage:logo.svg[Logo]\n"), '![Logo](img/logo.svg)', 'imagesdir applied to inline image target');

is(conv("image::banner.png[Banner]\n"), '![Banner](banner.png)', 'block image conversion');

is(conv('Start [[sec_intro]]here.'), 'Start <a name="sec_intro"></a>here.', 'inline anchor replacement');

is(
   conv('xref:#topic[Topic] and xref:#fallback[]'),
   '[Topic](#topic) and [fallback](#fallback)',
   'basic internal xref macro conversion'
   );

is(
   conv('See <<quick_ref,Quick Ref>> and <<other>>'),
   'See [Quick Ref](#quick_ref) and [other](#other)',
   'basic xref shorthand conversion'
   );

is(conv('See <<bad id,Label>> and <<bad id>>'),
   'See <<bad id, Label>> and <<bad id>>',
   'xref shorthand with space-containing ID is preserved');

is(
   conv('xref:#bad id[Bad] and xref:other.adoc#bad id[]'),
   'xref:#bad id[Bad] and xref:other.adoc#bad id[]',
   'xref macro with space-containing fragment is preserved'
   );

is(conv('a < b and `x < y`'), 'a &lt; b and `x < y`', 'escape < outside monospace only');

is(conv("don't can't rock'n'roll"), "don\x{2019}t can\x{2019}t rock\x{2019}n\x{2019}roll", 'curly apostrophe replacement');

# Standalone curly-quote/apostrophe markers.

is(conv("a `'s escape"), "a \x{2019}s escape", 'standalone `\' marker resolves the reported round-trip bug');

is(conv("it's fine"), "it\x{2019}s fine", 'plain apostrophe form still works');

is(conv("the `code`'s value"), "the `code`'s value", 'regression guard: code span survives intact next to a plain apostrophe');

is(conv("say '`quoted`' now"), "say \x{2018}quoted\x{2019} now", 'paired single quote form uses single-quote curly default');

is(conv('say "`quoted`" now'), "say \x{201C}quoted\x{201D} now", 'paired double quote form uses double-quote curly default');

is(conv("a `' b"), "a \x{2019} b", 'lone closing single marker');

is(conv("a '` b"), "a \x{2018} b", 'lone opening single marker');

is(conv('a `" b'), "a \x{201D} b", 'lone closing double marker');

is(conv('a "` b'), "a \x{201C} b", 'lone opening double marker');

is(conv("it's `code`'s and '`quoted`'"),
   "it\x{2019}s `code`'s and \x{2018}quoted\x{2019}",
   'plain, code span, and paired form all correct in one line');

is(conv("open '` and close `' done"),
   "open \x{2018} and close \x{2019} done",
   'opposite markers on one line are a paired quote, not two standalone markers');

# Verified against downdoc source (lib/index.js) that downdoc's single
# "quotes" attribute governs BOTH paired forms identically (default
# "<q> </q>"), so the two forms are indistinguishable in downdoc's own
# output. That default is also not round-trip stable through
# Text::MarkdownAdoc: raw "<q>" HTML is unknown to it and gets
# progressively re-escaped as passthrough on every pass. This module
# deliberately deviates from that default (real curly characters, one
# attribute per form) to fix both problems at once, while still allowing
# the old shared "<q></q>" behavior via explicit "quotes"/"quotes-single"
# configuration (covered above).
SKIP:
{
   eval { require Text::MarkdownAdoc };
   skip('Text::MarkdownAdoc not installed; skipping round-trip stability check', 2) if $@;

   my $up   = Text::MarkdownAdoc->new();
   my $down = Text::AsciidocDown->new();

   my $adoc  = q{say "`quoted`" then '`single`' now};
   my $md1   = $down->convert($adoc);
   my $adoc2 = $up->convert($md1);
   my $md2   = $down->convert($adoc2);

   is($md1, "say \x{201C}quoted\x{201D} then \x{2018}single\x{2019} now",
      'round-trip: default curly-quote Markdown output matches expectation');
   is($md2, $md1, 'round-trip: Markdown -> AsciiDoc -> Markdown reaches a stable fixpoint for paired quotes');
}

# Inline AsciiDoc passthrough (+++...+++) must survive completely
# unprocessed: no "<" escaping, no quote/format substitution, no
# attribute/macro expansion. Real AsciiDoc passthrough content is meant
# to be emitted verbatim, but it was previously corrupted because nothing
# recognized the "+++...+++" markers before escape_lt_outside_monospace()
# ran, so it treated the content as ordinary text.
is(conv('say +++<q>x</q>+++ now'), 'say <q>x</q> now', 'inline passthrough content survives verbatim, including "<"');

is(conv('a +++*not bold*+++ b'), 'a *not bold* b', 'inline passthrough content is not subject to inline formatting');

is(conv('a +++{not-an-attr}+++ b'), 'a {not-an-attr} b', 'inline passthrough content is not subject to attribute substitution');

is(conv("a +++'`still passthrough`'+++ b"), "a '\x{60}still passthrough\x{60}' b", 'inline passthrough content is not subject to quote substitution');

# This is what actually breaks without the fix: Text::MarkdownAdoc wraps
# any HTML tag it does not recognize (such as the old shared "<q></q>"
# downdoc-parity setting) as "+++<tag>+++...+++</tag>+++" passthrough on
# the way back to AsciiDoc. Before this fix, the next Text::AsciidocDown
# pass corrupted that passthrough by escaping its "<" to "&lt;", and the
# corruption was permanent (a stable but wrong fixpoint), not merely
# unstable. Verified end-to-end with the installed Text::MarkdownAdoc.
SKIP:
{
   eval { require Text::MarkdownAdoc };
   skip('Text::MarkdownAdoc not installed; skipping passthrough round-trip check', 2) if $@;

   my $up   = Text::MarkdownAdoc->new();
   my $down = Text::AsciidocDown->new(attributes => {quotes => '<q> </q>', 'quotes-single' => '<q> </q>'});

   my $adoc  = q{say "`quoted`" now};
   my $md1   = $down->convert($adoc);
   my $adoc2 = $up->convert($md1);
   my $md2   = $down->convert($adoc2);

   is($md1, 'say <q>quoted</q> now', 'shared <q></q> downdoc-parity setting still works as configured');
   is($md2, $md1, 'round-trip through the <q></q> setting reaches a correct, uncorrupted fixpoint (passthrough preserved)');
}

done_testing;
