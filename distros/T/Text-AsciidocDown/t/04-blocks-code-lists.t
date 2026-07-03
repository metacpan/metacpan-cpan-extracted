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
  conv("[#code_block]\n.Literal Title\n indented line\n"),
  "<a name=\"code_block\"></a>**Literal Title**\n\n```\nindented line\n```",
  'block title and ID on literal paragraph'
);

is(
  conv("[source,ruby]\n----\nputs 'hello'\n----\n"),
  "```ruby\nputs 'hello'\n```",
  'source block with language'
);

is(
  conv("....\nline 1\nline 2\n....\n"),
  "```\nline 1\nline 2\n```",
  'literal/listing style delimited block'
);

is(
  conv(" \$ pwd\n /tmp\n"),
  "```console\n\$ pwd\n/tmp\n```",
  'promoted console block from literal paragraph'
);

is(
  conv("[source]\n----\nputs 'x' # <1>\nputs 'y' # <.>\n----\n"),
  "```\nputs 'x' # \x{2460}\nputs 'y' # \x{2460}\n```",
  'callouts in verbatim block'
);

is(
  conv("* one\n** two\n.. three\n"),
  "* one\n  * two\n  1. three",
  'nested mixed list handling'
);

is(
  conv("* [x] done\n* [ ] todo\n"),
  "* [x] done\n* [ ] todo",
  'checklist preservation as markdown task list'
);

is(
  conv("Term:: Description\n"),
  "* **Term**\n  Description",
  'description list rendered as emphasized term plus detail'
);

is(
  conv("[qanda]\nWhat is this?:: A thing\nHow many?:: Two\n"),
  "1. _What is this?_\n  A thing\n1. _How many?_\n  Two",
  'qanda list behavior'
);

is(
  conv("* item\n+\nattached paragraph\n"),
  "* item\n  attached paragraph",
  'list continuation attaches following paragraph'
);

done_testing;
