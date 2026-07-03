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
  conv("|===\n|A |B\n|1 |2\n|===\n"),
  "| A | B |\n| --- | --- |\n| 1 | 2 |",
  'implicit header table conversion'
);

is(
  conv("[%header,cols=2*]\n|===\n|H1\n|H2\n|R1\n|R2\n|===\n"),
  "| H1 | H2 |\n| --- | --- |\n| R1 | R2 |",
  'explicit header and cols repeater'
);

is(
  conv("[cols=\"<,^,>\"]\n|===\n|A |B |C\n|1 |2 |3\n|===\n"),
  "| A | B | C |\n| :-- | :-: | --: |\n| 1 | 2 | 3 |",
  'cols alignment conversion'
);

is(
  conv("ifdef::show[Visible]\nifndef::show[Hidden]\n"),
  'Hidden',
  'single-line conditionals evaluated'
);

is(
  conv(":show:\nifdef::show[]\nA\nifndef::show[]\nB\nendif::[]\nendif::[]\n"),
  'A',
  'nested block conditionals evaluated'
);

is(
  conv("\\ifdef::flag[]\n"),
  'ifdef::flag[]',
  'escaped conditional directive preserved'
);

is(
  conv("= T\n\ninclude::chap.adoc[]\n\n== S\n"),
  "# T\n\n## S",
  'include directive dropped by default'
);

is(
  conv("= Doc\n\n== First Section\n\nSee xref:First Section[] and <<First Section>>.\n"),
  "# Doc\n\n## First Section\n\nSee [First Section](#_first_section) and <<First Section>>.",
  'forward natural xref fill-in via heading title works in macro form'
);

is(
  conv(":idprefix: sec_\n:idseparator: -\n\n== A B\n\nSee xref:#sec_a-b[]\n"),
  "## A B\n\nSee [sec_a-b](#sec_a-b)",
  'idprefix and idseparator honored in generated ids and xrefs'
);

done_testing;
