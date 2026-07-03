use strict;
use warnings;

use Test::More;

use Text::AsciidocDown;

sub conv {
  my ($input, $opts) = @_;
  my $converter = Text::AsciidocDown->new();
  return $converter->convert($input, $opts || {});
}

is(
  conv('*bold* _emphasis_ and `mono`'),
  '*bold* _emphasis_ and `mono`',
  'strong, emphasis, monospace basic forms'
);

is(
  conv('alpha*no*beta and alpha_no_beta and alpha#no#beta'),
  'alpha*no*beta and alpha_no_beta and alpha#no#beta',
  'format markers do not apply inside words'
);

is(
  conv('#mark# and [.line-through]#gone#'),
  '<mark>mark</mark> and ~~gone~~',
  'mark and line-through conversion'
);

is(
  conv(":markdown-strikethrough: <del> </del>\n\n[.line-through]#gone#\n"),
  '<del>gone</del>',
  'strikethrough uses configurable mark pair'
);

is(
  conv("say \"`quoted`\" then '`single`'"),
  'say <q>quoted</q> then <q>single</q>',
  'quote replacement with default quote pair'
);

is(
  conv(":quotes: &ldquo; &rdquo;\n\n\"`hello`\"\n"),
  '&ldquo;hello&rdquo;',
  'quote replacement can be configured'
);

is(
  conv('Visit https://example.org/docs[Docs] now.'),
  'Visit [Docs](https://example.org/docs) now.',
  'URL macro conversion'
);

is(
  conv('See link:README.md[Readme].'),
  'See [Readme](README.md).',
  'link macro conversion'
);

is(
  conv('Escape \\https://example.org[Docs] and \\link:README.md[Readme].'),
  'Escape <span>https://</span>example.org[Docs] and link:README.md[Readme].',
  'escaped URL and link macros are preserved/obscured'
);

is(
  conv(":hide-uri-scheme:\n\nhttps://example.org\n"),
  '[example.org](https://example.org)',
  'hide-uri-scheme uses URL without scheme as visible text'
);

is(
  conv('image:assets/logo.svg[Logo]'),
  '![Logo](assets/logo.svg)',
  'inline image conversion'
);

is(
  conv('image:assets/logo.svg[]'),
  '![logo](assets/logo.svg)',
  'inline image alt fallback from basename'
);

is(
  conv(":imagesdir: img\n\nimage:logo.svg[Logo]\n"),
  '![Logo](img/logo.svg)',
  'imagesdir applied to inline image target'
);

is(
  conv("image::banner.png[Banner]\n"),
  '![Banner](banner.png)',
  'block image conversion'
);

is(
  conv('Start [[sec_intro]]here.'),
  'Start <a name="sec_intro"></a>here.',
  'inline anchor replacement'
);

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

is(
  conv('See <<bad id,Label>> and <<bad id>>'),
  'See <<bad id, Label>> and <<bad id>>',
  'xref shorthand with space-containing ID is preserved'
);

is(
  conv('xref:#bad id[Bad] and xref:other.adoc#bad id[]'),
  'xref:#bad id[Bad] and xref:other.adoc#bad id[]',
  'xref macro with space-containing fragment is preserved'
);

is(
  conv('a < b and `x < y`'),
  'a &lt; b and `x < y`',
  'escape < outside monospace only'
);

is(
  conv("don't can't rock'n'roll"),
  "don\x{2019}t can\x{2019}t rock\x{2019}n\x{2019}roll",
  'curly apostrophe replacement'
);

done_testing;
