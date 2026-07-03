use strict;
use warnings;

use Test::More;

use Text::AsciidocDown;

sub conv {
  my ($input, $opts) = @_;
  my $converter = Text::AsciidocDown->new();
  return $converter->convert($input, $opts || {});
}

is(conv(''), '', 'empty document');

is(
  conv("= Document Title\n"),
  '# Document Title',
  'doctitle only'
);

is(
  conv("= Document Title\nAuthor Name\n:v: 1\n\nBody line\n"),
  "# Document Title\n\nBody line",
  'header and body with consumed header metadata'
);

is(
  conv(":name: ACME\n\nWelcome to {name}\n"),
  'Welcome to ACME',
  'attribute definition and reference in paragraph'
);

is(
  conv(":proj: Atlas\n\n== {proj} Guide\n"),
  '## Atlas Guide',
  'attribute reference in heading'
);

is(
  conv('Hello {missing}'),
  'Hello {missing}',
  'unresolved attribute remains unchanged'
);

is(
  conv(":one: A\n:two: B\n\n{one} and {two}\n"),
  'A and B',
  'multiple attribute references in one line'
);

is(
  conv("alpha\n\n'''\n\nomega\n"),
  "alpha\n\n---\n\nomega",
  'thematic break conversion'
);

is(
  conv("first\n\n<<<\n\nsecond\n"),
  "first\n\nsecond",
  'page break dropped'
);

is(
  conv("= T\n\ntoc::[]\n\n== S\n"),
  "# T\n\n## S",
  'toc macro dropped'
);

is(
  conv(":markdown-line-break: <br>\n\nline 1 +\nline 2\n"),
  "line 1<br>\nline 2",
  'hard line break converted using configured break mark'
);

done_testing;
